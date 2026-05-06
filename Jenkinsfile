pipeline {
    agent any
    
    tools {
        nodejs 'node18'
    }

    environment {
        SAJAT_TITKUNK = credentials('TESZT_API_KULCS')
    }

    stages {
        stage('Függőségek telepítése') {
            steps {
                echo 'NPM csomagok letöltése...'
                sh 'npm install' 
            }
        }
        
        // --- ÚJ RÉSZ: PÁRHUZAMOS FUTTATÁS ---
        stage('Komplex Tesztelési Fázis') {
            // A parallel blokkon belüli stage-ek egyszerre fognak elindulni!
            parallel {
                
                stage('Gyors Egységtesztek') {
                    steps {
                        echo '1. szál: Node.js tesztek indítása...'
                        sh 'npm test'
                    }
                }
                
                stage('Lassú Integrációs Tesztek') {
                    steps {
                        echo '2. szál: Adatbázis tesztek szimulálása...'
                        // A 'sleep' paranccsal szimulálunk egy 5 másodperces lassú tesztet
                        sleep time: 5, unit: 'SECONDS'
                        echo '2. szál: Adatbázis tesztek sikeresek!'
                    }
                }
                
                stage('Biztonsági Ellenőrzés') {
                    steps {
                        echo '3. szál: Kód átvizsgálása sebezhetőségek után...'
                        sleep time: 2, unit: 'SECONDS'
                        echo '3. szál: A kód biztonságos!'
                    }
                }
                
            }
        }
        // --- PÁRHUZAMOS RÉSZ VÉGE ---
        
        stage('Csomagolás') {
            steps {
                echo 'Minden teszt sikeres! Csomagolás indul...'
                sh 'tar -czvf kesz-alkalmazas.tar.gz test.js package.json'
            }
        }
    }
    
    post {
        success {
            echo 'Mentjük a fájlt...'
            archiveArtifacts artifacts: 'kesz-alkalmazas.tar.gz', fingerprint: true
        }
    }
}
