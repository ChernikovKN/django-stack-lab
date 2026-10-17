
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
                    hostname
                    docker version
                    docker compose version
                    ansible --version
                '''
            }
        }

        stage('Build Docker Image') {
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
                      -e DB_NAME=ci_db \
                      -e DB_USER=ci_user \
                      -e DB_PASSWORD=ci-placeholder \
                      -e DB_HOST=db \
                      "django-stack-ci:${BUILD_NUMBER}" \
                      python manage.py check
                '''
            }
        }
    }

    post {
        success {
            echo 'Docker build and Django checks passed'
        }

        failure {
            echo 'CI Pipeline failed'
        }

        always {
            echo 'Pipeline finished'
        }
    }
}
