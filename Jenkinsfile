pipeline {
    agent {
        label 'spot-agents'
    }

    environment {
        AWS_REGION = 'eu-west-1'
        ECR_REGISTRY = '867344428625.dkr.ecr.eu-west-1.amazonaws.com'
        ECR_REPOSITORY = 'whoami-service-dev'
        IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"
        LATEST_IMAGE = "${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
        APP_HOST_NAME_TAG = 'whoami-service-dev-app-host'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install & Test') {
            steps {
                dir('backend') {
                    sh '''
                    uv sync
                    uv run pytest --cov=src tests/
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                dir('backend') {
                    sh "docker build -t ${IMAGE_NAME} -t ${LATEST_IMAGE} ."
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                docker push ${IMAGE_NAME}
                docker push ${LATEST_IMAGE}
                '''
            }
        }

        stage('Deploy to App Host') {
            steps {
                script {
                    env.APP_HOST_IP = sh(
                        script: """
                        aws ec2 describe-instances \\
                            --region ${AWS_REGION} \\
                            --filters "Name=tag:Name,Values=${APP_HOST_NAME_TAG}" "Name=instance-state-name,Values=running" \\
                            --query "Reservations[0].Instances[0].PrivateIpAddress" \\
                            --output text
                        """,
                        returnStdout: true
                    ).trim()

                    echo "Found App Host IP: ${env.APP_HOST_IP}"

                    if (env.APP_HOST_IP == 'None' || env.APP_HOST_IP == '') {
                        error("Could not find a running EC2 instance with tag Name=${APP_HOST_NAME_TAG}")
                    }
                }

                sshagent(['app-host-ssh-key']) {
                    // Create the monitoring directory on remote host
                    sh "ssh -o StrictHostKeyChecking=no ec2-user@${APP_HOST_IP} 'mkdir -p /home/ec2-user/monitoring'"
                    
                    // Transfer the monitoring stack configuration
                    sh "scp -o StrictHostKeyChecking=no -r monitoring/* ec2-user@${APP_HOST_IP}:/home/ec2-user/monitoring/"

                    // Dynamically generate the .env file with Jenkins credentials and transfer it
                    withCredentials([
                        string(credentialsId: 'slack-webhook-url', variable: 'SLACK_WEBHOOK_URL'),
                        string(credentialsId: 'slack-member-id', variable: 'SLACK_MEMBER_ID')
                    ]) {
                        sh '''
                        echo "SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}" > monitoring/.env
                        echo "SLACK_MEMBER_ID=${SLACK_MEMBER_ID}" >> monitoring/.env
                        '''
                        sh "scp -o StrictHostKeyChecking=no monitoring/.env ec2-user@${APP_HOST_IP}:/home/ec2-user/monitoring/.env || true"
                        // Clean up the local .env immediately after transfer to prevent secrets from lingering in workspace
                        sh "rm -f monitoring/.env"
                    }

                    // Transfer the deploy script from ci-scripts
                    sh "scp -o StrictHostKeyChecking=no ci-scripts/deploy.sh ec2-user@${APP_HOST_IP}:/home/ec2-user/deploy.sh"
                    
                    // Execute the deployment commands on the remote server
                    sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@${APP_HOST_IP} 'chmod +x deploy.sh && bash /home/ec2-user/deploy.sh "${ECR_REGISTRY}" "${AWS_REGION}" "${LATEST_IMAGE}"'
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
