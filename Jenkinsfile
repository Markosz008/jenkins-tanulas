pipeline {
    agent any
    
    tools {
        nodejs 'node18'
    }

    environment {
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
                echo 'Tesztek futtatása...'
                sh 'npm test'
            }
        }
        
        // ÚJ SZAKASZ: Csomagolás
        stage('Csomagolás (Package)') {
            steps {
                echo 'A kész alkalmazás becsomagolása telepítéshez...'
                // A 'tar' parancs készít egy tömörített fájlt a kódjainkból
                sh 'tar -czvf kesz-alkalmazas.tar.gz test.js package.json'
            }
        }
    }
    
    // ÚJ BLOKK: Post action (Utómunkálatok)
    post {
        success {
            echo 'A Pipeline sikeres! Mentjük a kész csomagot...'
            // Az archiveArtifacts parancs menti el a fájlt a Jenkins felületére
            archiveArtifacts artifacts: 'kesz-alkalmazas.tar.gz', fingerprint: true
        }
    }
}
