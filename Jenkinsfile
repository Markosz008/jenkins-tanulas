pipeline {
    agent any
    
    tools {
        nodejs 'node18'
    }

    environment {
        SAJAT_TITKUNK = credentials('TESZT_API_KULCS')
        // Bekérjük a Discord Webhook URL-t a titkok közül!
        DISCORD_URL = credentials('DISCORD_WEBHOOK')
    }

    stages {
        stage('Tesztelés') {
            steps {
                echo 'Tesztek futtatása...'
                sh 'npm test'
            }
        }
        stage('Csomagolás') {
            steps {
                echo 'Csomagolás indul...'
                sh 'tar -czvf kesz-alkalmazas.tar.gz test.js package.json'
            }
        }
    }
    
    // Ide jön az értesítés!
    post {
        always {
            archiveArtifacts artifacts: 'kesz-alkalmazas.tar.gz', fingerprint: true
        }
        success {
            echo 'Sikeres futás! Értesítés küldése Discordra...'
            // A discordSend parancsot a plugin adta nekünk
            discordSend description: "✅ HIBÁTLAN FUTÁS! Az új verzió sikeresen lefordítva és tesztelve. (Build #${BUILD_NUMBER})", 
                        link: env.BUILD_URL, 
                        result: currentBuild.currentResult, 
                        title: "Jenkins Projekt: ${JOB_NAME}", 
                        webhookURL: env.DISCORD_URL
        }
        failure {
            echo 'Valami elromlott! Riasztás küldése Discordra...'
            discordSend description: "❌ BAJ VAN! A Pipeline elbukott. Kérlek azonnal nézd meg a logokat! (Build #${BUILD_NUMBER})", 
                        link: env.BUILD_URL, 
                        result: currentBuild.currentResult, 
                        title: "Jenkins Projekt: ${JOB_NAME}", 
                        webhookURL: env.DISCORD_URL
        }
    }
}
