
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

        stage('Inspect Build') {
            steps {
                echo "Job: ${env.JOB_NAME}"
                echo "Build: ${env.BUILD_NUMBER}"
                echo "Commit: ${env.GIT_COMMIT ?: 'unknown'}"

                sh 'pwd'
            }
        }

        stage('Validate Project') {
            steps {
                script {
                    def requiredFiles = [
                        'compose.yaml',
                        'app/manage.py',
                        'app/Dockerfile',
                        'app/requirements.txt',
                        'automation/deploy.yml'
                        'app/missing.py'
                    ]

                    requiredFiles.each { file ->
                        if (!fileExists(file)) {
                            error("Missing file: ${file}")
                        }

                        echo "Found: ${file}"
                    }
                }
            }
        }

        stage('Check Dockerfile') {
            steps {
                sh '''
                    set -eu

                    grep -Eq '^FROM[[:space:]]+' app/Dockerfile
                    grep -Eq '^USER[[:space:]]+' app/Dockerfile

                    echo "Dockerfile basic checks passed"
                '''
            }
        }
    }

    post {
        success {
            echo 'CI checks passed'
        }

        failure {
            echo 'CI checks failed'
        }

        always {
            echo 'Pipeline completed'
        }
    }
}
