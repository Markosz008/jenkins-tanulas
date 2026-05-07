pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Válaszd ki a műveletet (apply = építés, destroy = törlés)')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        DISCORD_URL           = credentials('DISCORD_WEBHOOK')
    }

    stages {
        stage('Terraform Init') {
            steps {
                // Inicializálja a Terraformot és a S3 backendet
                sh 'terraform init -input=false -force-copy'
            }
        }

        stage('Terraform Action') {
            steps {
                script {
                    if (params.ACTION == 'apply') {
                        echo "--- Infrastruktúra kiépítése indítása ---"
                        sh 'terraform apply --auto-approve'
                    } else {
                        echo "--- Infrastruktúra lebontása indítása ---"
                        sh 'terraform destroy --auto-approve'
                    }
                }
            }
        }

stage('Ansible Provisioning') {
            steps {  // <--- EZ HIÁNYZOTT!
                script {
                    def bastionIp = sh(script: "terraform output -raw bastion_ip", returnStdout: true).trim()
                    def dbHost = sh(script: "terraform output -raw db_endpoint", returnStdout: true).trim()
                    def jenkinsKey = "/Users/markosz/.ssh/id_rsa"

                    echo "Várakozás 60 másodpercig az instance-ok indulására..."
                    sleep 60

                    withEnv(["DB_HOST=${dbHost}"]) {
                        sh "ansible-playbook -i aws_ec2.yml --private-key ${jenkinsKey} -u ec2-user '--ssh-common-args=-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -q ec2-user@${bastionIp} -i ${jenkinsKey} -o StrictHostKeyChecking=no\"' setup2.yml"
                    }
                }
            } // <--- EZ ZÁRJA A steps-et
        } // <--- EZ ZÁRJA A stage-et    } // EZ A steps VAGY pipeline ZÁRÓJELE (attól függ, hol tartasz)

    post {
        success {
            script {
                discordSend description: "Művelet: ${params.ACTION} - Állapot: ✅ SIKERES", 
                            title: "Project: ${JOB_NAME}", 
                            webhookURL: env.DISCORD_URL
            }
        }
        failure {
            script {
                discordSend description: "Művelet: ${params.ACTION} - Állapot: ❌ HIBA TÖRTÉNT", 
                            title: "Project: ${JOB_NAME}", 
                            webhookURL: env.DISCORD_URL
            }
        }
    }
}
