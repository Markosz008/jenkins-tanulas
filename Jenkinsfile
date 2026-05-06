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
                    // Lekérjük mindkét IP címet a Terraform outputból
                    def bastionIp = sh(script: "terraform output -raw bastion_ip", returnStdout: true).trim()
                    def webPrivateIp = sh(script: "terraform output -raw web_private_ip", returnStdout: true).trim()
                    
                    echo "Bastion Host IP: ${bastionIp}"
                    echo "Target Private Server IP: ${webPrivateIp}"
                    
                    // Kulcs elökészítése
                    sh "cp /var/jenkins_home/id_rsa ./deploy_key"
                    sh "chmod 400 ./deploy_key"
                    
                    echo "Waiting for infrastructure to be ready..."
                    sleep 30

                    // Az Ansible "mágia": ProxyCommand használata az átugráshoz
                    // Ez azt mondja: "Csatlakozz a privát IP-re, de a Bastionon keresztül ugrálva"
                    sh """
                        ansible-playbook -i ${webPrivateIp}, \
                        --private-key ./deploy_key \
                        -u ec2-user \
                        --ssh-common-args="-o StrictHostKeyChecking=no -o ProxyCommand='ssh -W %h:%p -q ec2-user@${bastionIp} -i ./deploy_key -o StrictHostKeyChecking=no'" \
                        setup.yml
                    """
                    
                    sh "rm ./deploy_key"
                }
            }
        }
    }

    post {
        failure {
            echo 'Build Failed!'
            discordSend description: "❌ Bastion Architecture Build #${BUILD_NUMBER} failed!", 
                        title: "Project: ${JOB_NAME}", 
                        webhookURL: env.DISCORD_URL
        }
        success {
            echo 'Build Success!'
            discordSend description: "✅ Bastion Architecture Build #${BUILD_NUMBER} successful!\nWeb Server is now secured in a Private Subnet.", 
                        title: "Project: ${JOB_NAME}", 
                        webhookURL: env.DISCORD_URL
        }
    }
}
