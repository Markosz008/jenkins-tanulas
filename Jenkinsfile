pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'A projekt fordítása a GitHubról letöltött kód alapján...'
            }
        }
        stage('Test') {
            steps {
                echo 'Tesztek futtatása AUTOMATIKUSAN indítva!!!'
                sh 'echo "Sikeres teszt!"'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Telepítés folyamatban...'
            }
        }
    }
}
