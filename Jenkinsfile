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
                    // Lekérjük az IP címeket
                    def bastionIp = sh(script: "terraform output -raw bastion_ip", returnStdout: true).trim()
                    def webPrivateIp = sh(script: "terraform output -raw web_private_ip", returnStdout: true).trim()
                    
                    echo "Bastion Host IP: ${bastionIp}"
                    echo "Target Private Server IP: ${webPrivateIp}"
                    
                    // A Jenkins eredeti kulcsát használjuk közvetlenül
                    def jenkinsKey = "/var/jenkins_home/id_rsa"
                    
                    echo "Waiting for infrastructure to be ready..."
                    sleep 30

                    // Az Ansible-nek megadjuk a közvetlen utat a kulcshoz a ProxyCommand-ban is
                    sh """
                        ansible-playbook -i ${webPrivateIp}, \
                        --private-key ${jenkinsKey} \
                        -u ec2-user \
                        --ssh-common-args="-o StrictHostKeyChecking=no -o ProxyCommand='ssh -W %h:%p -q ec2-user@${bastionIp} -i ${jenkinsKey} -o StrictHostKeyChecking=no'" \
                        setup.yml
                    """
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
