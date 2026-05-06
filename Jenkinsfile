pipeline {
    agent any
    
    // Itt mondjuk meg a Jenkinsnek, hogy töltse le és használja a Node.js-t
    tools {
        nodejs 'node18' // Ennek egyeznie kell azzal a névvel, amit a Tools-ban adtál meg!
    }

    stages {
        stage('Függőségek telepítése (Build)') {
            steps {
                echo 'NPM csomagok letöltése...'
                // Ez a parancs letöltené a szükséges könyvtárakat (most még nincsenek)
                sh 'npm install' 
            }
        }
        
        stage('Automatizált Tesztelés') {
            steps {
                echo 'Node.js tesztszkript futtatása...'
                // Ez a parancs futtatja le a package.json-ban definiált "test" scriptet
                sh 'npm test'
            }
        }
        
        stage('Telepítés (Deploy)') {
            steps {
                echo 'Sikeres teszt! Az alkalmazás mehet az éles szerverre.'
            }
        }
    }
}
