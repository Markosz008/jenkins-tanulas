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
                    / Lekérjük a publikus IP-t
                    def serverIp = sh(script: "terraform output -raw public_ip", returnStdout: true).trim()
                    echo "Szerver IP címe: ${serverIp}"
                    
                    // KERÜLŐÚT: Átmásoljuk a kulcsot a munkaterületre, ott biztosan van jogunk módosítani
                    sh "cp /var/jenkins_home/id_rsa ./deploy_key"
                    sh "chmod 400 ./deploy_key"
                    
                    echo "Várakozás az SSH-ra (30 mp)..."
                    sleep 30

                    // Futtatjuk az Ansible-t az ideiglenes kulccsal
                    sh "ansible-playbook -i ${serverIp}, --private-key ./deploy_key -u ec2-user --ssh-common-args='-o StrictHostKeyChecking=no' setup.yml"
                    
                    // Töröljük a másolt kulcsot a build végén (biztonság)
                    sh "rm ./deploy_key"
                }
            }
        }
    }

    post {
        failure {
            echo 'Hiba történt!'
            discordSend description: "❌ AWS Terraform + Ansible Build #${BUILD_NUMBER} elbukott!", 
                        title: "Hiba a projektben: ${JOB_NAME}", 
                        webhookURL: env.DISCORD_URL
        }
        success {
            echo 'Siker!'
            discordSend description: "✅ AWS Terraform + Ansible Build #${BUILD_NUMBER} sikeresen lefutott!", 
                        title: "Siker: ${JOB_NAME}", 
                        webhookURL: env.DISCORD_URL
        }
    }
}
