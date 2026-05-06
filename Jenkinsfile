pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        DISCORD_URL           = credentials('DISCORD_WEBHOOK')
    }

    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init -input=false -force-copy'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply --auto-approve'
            }
        }

        stage('Ansible Provisioning') {
            steps {
                script {
                    def serverIp = sh(script: "terraform output -raw public_ip", returnStdout: true).trim()
                    echo "Target Server IP: ${serverIp}"
                    
                    // Workaround for SSH key permissions
                    sh "cp /var/jenkins_home/id_rsa ./deploy_key"
                    sh "chmod 400 ./deploy_key"
                    
                    echo "Waiting for SSH to be ready..."
                    sleep 30

                    sh "ansible-playbook -i ${serverIp}, --private-key ./deploy_key -u ec2-user --ssh-common-args='-o StrictHostKeyChecking=no' setup.yml"
                    
                    sh "rm ./deploy_key"
                }
            }
        }
    }

    post {
        failure {
            echo 'Build Failed!'
            discordSend description: "❌ Build #${BUILD_NUMBER} failed!", 
                        title: "Project: ${JOB_NAME}", 
                        webhookURL: env.DISCORD_URL
        }
        success {
            echo 'Build Success!'
            discordSend description: "✅ Build #${BUILD_NUMBER} successful!", 
                        title: "Project: ${JOB_NAME}", 
                        webhookURL: env.DISCORD_URL
        }
    }
}
