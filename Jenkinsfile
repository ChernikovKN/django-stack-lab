
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Check Agent') {
            steps {
                sh '''
                    set -eu
                    whoami
                    id
                    docker info --format '{{.ServerVersion}}'
                '''
            }
        }

        stage('Build Image') {
            steps {
                sh '''
                    set -eu

                    docker build \
                        -t "django-stack-ci:${BUILD_NUMBER}" \
                        ./app
                '''
            }
        }

        stage('Django Check') {
            steps {
                sh '''
                    set -eu

                    docker run --rm \
                        -e DJANGO_SECRET_KEY=ci-test-only \
                        -e DB_NAME=labdb \
                        -e DB_USER=labuser \
                        -e DB_PASSWORD=ci-placeholder \
                        -e DB_HOST=db \
                        "django-stack-ci:${BUILD_NUMBER}" \
                        python manage.py check
                '''
            }
        }

        stage('Integration Test') {
            steps {
                sh '''
                    sh ci/integration.sh \
                        "django-stack-ci:${BUILD_NUMBER}"
                '''
            }
        }
        
        stage('Deploy Staging') {
          input {
            message 'Развернуть CI-образ в staging?'
            ok 'Deploy'
          }

          steps {
            withCredentials([
              string(
                  credentialsId: 'staging-db-password',
                  variable: 'DB_PASSWORD'
              ),
              string(
                  credentialsId: 'staging-django-secret',
                  variable: 'DJANGO_SECRET_KEY'
              )
          ]) {
              sh '''
                  set +x
                  set -eu

                  export CI_IMAGE="django-stack-ci:${BUILD_NUMBER}"

                  ansible-playbook \
                      -i automation/inventory.ini \
                      automation/deploy-staging.yml
              '''
          }
      }
  }

    }

    post {
        always {
            sh(
                returnStatus: true,
                script: '''
                    CI_ID=$(printf '%s' \
                        "${JOB_NAME}-${BUILD_NUMBER}" \
                        | sha256sum | cut -c1-12)

                    docker rm -fv "djci-db-${CI_ID}" \
                        >/dev/null 2>&1 || true

                    docker network rm "djci-net-${CI_ID}" \
                        >/dev/null 2>&1 || true
                '''
            )

            echo 'CI cleanup finished'
        }

        success {
            echo 'CI SUCCESS'
        }

        failure {
            echo 'CI FAILED'
        }
    }
}
