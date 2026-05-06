pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Válaszd ki, hogy építeni vagy bontani akarsz')
    }

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

        stage('Terraform Action') {
            steps {
                script {
                    if (params.ACTION == 'apply') {
                        sh 'terraform apply --auto-approve'
                    } else {
                        sh 'terraform destroy --auto-approve'
                    }
                }
            }
        }

        stage('Ansible Provisioning') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    def bastionIp = sh(script: "terraform output -raw bastion_ip", returnStdout: true).trim()
                    def webPrivateIp = sh(script: "terraform output -raw web_private_ip", returnStdout: true).trim()
                    def jenkinsKey = "/var/jenkins_home/id_rsa"
                    
                    echo "Waiting for infrastructure to be ready..."
                    sleep 30

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
            discordSend description: "Művelet: ${params.ACTION} - Állapot: ✅ Sikeres!", 
            title: "Project: ${JOB_NAME}", 
            webhookURL: env.DISCORD_URL
        }
    }
}
