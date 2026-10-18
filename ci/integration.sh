
#!/bin/sh
set -eu

IMAGE="$1"

CI_ID=$(printf '%s' \
    "${JOB_NAME:-local}-${BUILD_NUMBER:-0}" \
    | sha256sum | cut -c1-12)

NETWORK="djci-net-${CI_ID}"
DB="djci-db-${CI_ID}"

# Одноразовый пароль исключительно для тестовой БД
DB_PASSWORD=$(cat /proc/sys/kernel/random/uuid)

# Не выводим пароль в лог
set +x

echo "Creating isolated CI network"
docker network create "$NETWORK"

echo "Starting test PostgreSQL"
docker run -d \
    --name "$DB" \
    --network "$NETWORK" \
    -e POSTGRES_DB=labdb \
    -e POSTGRES_USER=labuser \
    -e POSTGRES_PASSWORD="$DB_PASSWORD" \
    postgres:17-alpine >/dev/null

echo "Waiting for PostgreSQL"

READY=0

for i in $(seq 1 30); do
    if docker exec "$DB" \
        pg_isready \
        -h 127.0.0.1 \
        -U labuser \
        -d labdb >/dev/null 2>&1; then
        READY=1
        break
    fi

    sleep 2
done

if [ "$READY" -ne 1 ]; then
    echo "PostgreSQL is not ready"
    docker logs "$DB"
    exit 1
fi

echo "PostgreSQL is ready"

echo "Running Django migrations"

docker run --rm \
    --network "$NETWORK" \
    -e DJANGO_SECRET_KEY=ci-test-only \
    -e DB_NAME=labdb \
    -e DB_USER=labuser \
    -e DB_PASSWORD="$DB_PASSWORD" \
    -e DB_HOST="$DB" \
    -e DB_PORT=5432 \
    "$IMAGE" \
    python manage.py migrate --noinput

echo "Integration test PASSED"
