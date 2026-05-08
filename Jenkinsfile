pipeline {
    agent any
    parameters {
        choice(name: 'ACTION', choices: ['-', 'apply', 'destroy'], description: 'VÁLASSZ MŰVELETET!')
    }
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'eu-central-1'
        DISCORD_URL           = credentials('DISCORD_WEBHOOK')
        DB_PASS               = credentials('DB_PASSWORD')
        // A te felhasználóneveddel megadott image név
        DOCKER_IMAGE          = "markosz008/flask-app:latest"
    }

    stages {
        stage('Terraform Init') {
            steps {
                sh 'cd terraform && terraform init -input=false -force-copy'
            }
        }

        stage('Terraform Action') {
            steps {
                script {
                    if (params.ACTION == 'destroy') {
                        echo "--- Infrastruktúra TÖRLÉSE indítása ---"
                        sh "cd terraform && terraform destroy -var='db_password=${env.DB_PASS}' --auto-approve"
                    } else if (params.ACTION == 'apply') {
                        echo "--- Infrastruktúra KIÉPÍTÉSE indítása ---"
                        sh "cd terraform && terraform apply -var='db_password=${env.DB_PASS}' --auto-approve"
                    } else {
                        error "Hiba: Válassz egy akciót (apply vagy destroy)!"
                    }
                }
            }
        }

        // --- DOCKER SZAKASZ BESZÚRÁSA ---
        stage('Docker Build & Push') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    // Itt használd azt a Credential ID-t, amit Jenkinsben a Docker Hub-hoz létrehoztál!
                    // Ha nem 'docker-hub-id' néven mentetted el, írd át az alábbi sort!
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-id', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        sh "docker build --platform linux/amd64 -t ${env.DOCKER_IMAGE} ."
                        sh "docker push ${env.DOCKER_IMAGE}"
                    }
                }
            }
        }
        // --- DOCKER SZAKASZ VÉGE ---

        stage('Ansible Provisioning') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    def bastionIp = sh(script: "cd terraform && terraform output -raw bastion_ip", returnStdout: true).trim()
                    def dbHost = sh(script: "cd terraform && terraform output -raw db_endpoint", returnStdout: true).trim()
                    def jenkinsKey = "/Users/markosz/.ssh/id_rsa"

                    echo "Várakozás 60 másodpercig az instance-ok indulására..."
                    sleep 60

                    withEnv(["DB_HOST=${dbHost}", "DB_PASS=${env.DB_PASS}"]) {
                        sh """
                        cd ansible && ansible-playbook -i aws_ec2.yml \
                        --private-key ${jenkinsKey} \
                        -u ec2-user \
                        --ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ec2-user@${bastionIp} -i ${jenkinsKey} -o StrictHostKeyChecking=no"' \
                        setup2.yml
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                discordSend description: "Sikeres Build! Művelet: ${params.ACTION}", 
                            footer: "Jenkins Pipeline", 
                            link: "https://github.com/Markosz008/jenkins-tanulas", 
                            result: "SUCCESS", 
                            title: "Infrastructure Task Finished", 
                            webhookURL: "${env.DISCORD_URL}"
            }
        }
        failure {
            script {
                discordSend description: "Hiba történt a Build során!", 
                            result: "FAILURE", 
                            webhookURL: "${env.DISCORD_URL}"
            }
        }
    }
}