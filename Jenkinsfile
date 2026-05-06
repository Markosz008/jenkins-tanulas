pipeline {
    agent any

    environment {
        // Ellenőrizd, hogy a Jenkinsben az ID-k pontosan ezek!
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        DISCORD_URL           = credentials('DISCORD_WEBHOOK')
    }

   stage('Terraform Init') {
            steps {
                // A -force-copy automatikusan átmásolja a helyi state-et az S3-ba kérdezés nélkül
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
            // Letisztultabb Discord küldés
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
