
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        booleanParam(
            name: 'BREAK_BUILD',
            defaultValue: false,
            description: 'Имитировать ошибку сборки'
        )
    }

    environment {
        LAB_NAME = 'django-stack-lab'
    }

    stages {
        stage('Inspect Agent') {
            steps {
                sh '''
                    echo "Workspace: $PWD"
                    echo "Hostname: $(hostname)"
                    echo "Project: $LAB_NAME"
                '''
            }
        }

        stage('Groovy Example') {
            steps {
                script {
                    def services = ['nginx', 'app', 'db']

                    services.each { service ->
                        echo "Service: ${service}"
                    }
                }
            }
        }

        stage('Smoke Test') {
            steps {
                sh 'echo "Smoke test passed"'
            }
        }

        stage('Controlled Failure') {
            when {
                expression { params.BREAK_BUILD }
            }

            steps {
                sh 'exit 1'
            }
        }
    }

    post {
        success {
            echo 'Pipeline SUCCESS'
        }

        failure {
            echo 'Pipeline FAILED'
        }

        always {
            echo 'Pipeline finished'
        }
    }
}
