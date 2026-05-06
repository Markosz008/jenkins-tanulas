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
