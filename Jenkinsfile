pipeline {
    agent any
    
    tools {
        nodejs 'node18'
    }

    // Itt definiáljuk a környezeti változókat az egész Pipeline-ra vonatkozóan
    environment {
        // Létrehozunk egy SAJAT_TITKUNK változót, és beletöltjük a credentials() paranccsal
        // azt a titkot, amit az 1. lépésben TESZT_API_KULCS néven mentettünk el.
        SAJAT_TITKUNK = credentials('TESZT_API_KULCS')
    }

    stages {
        stage('Függőségek telepítése (Build)') {
            steps {
                echo 'NPM csomagok letöltése...'
                sh 'npm install' 
            }
        }
        
        stage('Automatizált Tesztelés') {
            steps {
                echo 'Node.js tesztszkript futtatása titkos kulccsal...'
                sh 'npm test'
            }
        }
    }
}
