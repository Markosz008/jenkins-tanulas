pipeline {
    agent any

    environment {
        // Itt kötjük össze a Jenkins titkait a Terraform környezeti változóival
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }

    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                // A 'plan' megmutatja, mit fog csinálni, de nem épít semmit
                sh 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            steps {
                // Az '--auto-approve' azért kell, mert a Jenkins nem tud "yes"-t gépelni
                sh 'terraform apply --auto-approve'
            }
        }
    }

    post {
        always {
            // Discord értesítés (ha még megvan a titkod a Jenkinsben)
            discordSend description: "AWS Infrastruktúra státusz: ${currentBuild.currentResult}", 
                        title: "Terraform Projekt: ${JOB_NAME}", 
                        webhookURL: credentials('DISCORD_WEBHOOK')
        }
    }
}
