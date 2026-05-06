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
                // A -force-copy automatikusan átviszi a régi állapotot az S3-ba
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
                // Itt egy kis trükk: megvárjuk, amíg a szerver elindul, majd futtatjuk az Ansible-t
                echo 'Várakozás a szerverre...'
                sleep 30 
                sh 'ansible-playbook -i localhost, setup.yml' 
                // Megjegyzés: Ez most csak egy teszt futtatás lesz localhoston, 
                // hogy lásd a Jenkinsben az Ansible kimenetet!
            }
        }
    }

    post {
        failure {
            echo 'Hiba történt!'
            discordSend description: "❌ AWS Terraform Build #${BUILD_NUMBER} elbukott!", 
                        title: "Hiba a projektben: ${JOB_NAME}", 
                        webhookURL: env.DISCORD_URL
        }
        success {
            echo 'Siker!'
            discordSend description: "✅ AWS Terraform Build #${BUILD_NUMBER} sikeresen lefutott!", 
                        title: "Siker: ${JOB_NAME}", 
                        webhookURL: env.DISCORD_URL
        }
    }
}
