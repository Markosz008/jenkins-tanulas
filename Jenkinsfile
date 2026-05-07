pipeline {
    agent any
    parameters {
        choice(name: 'ACTION', choices: ['-', 'apply', 'destroy'], description: 'VÁLASSZ MŰVELETET!')
    }
    environment {
        // A Te Jenkinsedben lévő pontos ID-k használata:
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'eu-central-1'
        DISCORD_URL           = credentials('DISCORD_WEBHOOK')
    }

    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init -input=false -force-copy'
            }
        }

stage('Terraform Action') {
            steps {
                script {
                    if (params.ACTION == 'destroy') {
                        echo "--- Infrastruktúra TÖRLÉSE indítása ---"
                        sh 'terraform destroy --auto-approve'
                    } else {
                        echo "--- Infrastruktúra KIÉPÍTÉSE indítása ---"
                        sh 'terraform apply --auto-approve'
                    }
                }
            }
        }
        stage('Ansible Provisioning') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    def bastionIp = sh(script: "terraform output -raw bastion_ip", returnStdout: true).trim()
                    def dbHost = sh(script: "terraform output -raw db_endpoint", returnStdout: true).trim()
                    def jenkinsKey = "/Users/markosz/.ssh/id_rsa"

                    echo "Várakozás 60 másodpercig az instance-ok indulására..."
                    sleep 60

                    // A DB_HOST átadása az Ansible-nek környezeti változóként
                    withEnv(["DB_HOST=${dbHost}"]) {
                        sh "ansible-playbook -i aws_ec2.yml --private-key ${jenkinsKey} -u ec2-user '--ssh-common-args=-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -q ec2-user@${bastionIp} -i ${jenkinsKey} -o StrictHostKeyChecking=no\"' setup2.yml"
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                discordSend description: "Sikeres Build! Az alkalmazás elérhető az ALB címen.", 
                            footer: "Jenkins Pipeline", 
                            link: "https://github.com/Markosz008/jenkins-tanulas", 
                            result: "SUCCESS", 
                            title: "Infrastructure & App Deployed", 
                            webhookURL: "${env.DISCORD_URL}"
            }
        }
        failure {
            script {
                if (env.DISCORD_URL) {
                    discordSend description: "Hiba történt a Build során!", 
                                result: "FAILURE", 
                                webhookURL: "${env.DISCORD_URL}"
                }
            }
        }
    }
}