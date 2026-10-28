
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

        
        stage('Resolve Version') {
            steps {
                script {
                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()

                    env.CI_IMAGE = "127.0.0.1:5000/django-stack:${env.GIT_SHA}"

                    echo "Building image: ${env.CI_IMAGE}"
                }
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
                        -t "$CI_IMAGE" \
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
                        "$CI_IMAGE" \
                        python manage.py check
                '''
            }
        }

        stage('Integration Test') {
            steps {
                sh '''
                    sh ci/integration.sh "$CI_IMAGE"
                '''
            }
        }
        


        stage('Push Image') {
            steps {
                sh '''
                   set -eu

                   echo "Pushing $CI_IMAGE"

                   docker push "$CI_IMAGE"

                   echo "Published image digest:"

                   docker image inspect "$CI_IMAGE" --format '{{json .RepoDigests}}'
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

                  echo CI_IMAGE

                  CI_IMAGE: "{{ lookup('env', 'CI_IMAGE') }}"

                  ansible-playbook \
                      -i automation/inventory.ini automation/deploy-staging.yml
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
