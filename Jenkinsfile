pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Válaszd ki a műveletet')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        DISCORD_URL           = credentials('DISCORD_WEBHOOK')
        IS_ONLY_DOCS          = "false"
    }

    stages {
        stage('Check Changes') {
            steps {
                script {
                    // Robusztusabb git diff lekérdezés
                    def diffCmd = 'git diff --name-only HEAD~1 HEAD || git diff --name-only HEAD^ HEAD || echo "INIT_BUILD"'
                    def changedFiles = sh(script: diffCmd, returnStdout: true).trim().split('\n')
                    
                    echo "Módosított fájlok: ${changedFiles}"
                    
                    def onlyDocs = true
                    for (file in changedFiles) {
                        // Ha bármi mást találunk, ami nem doksi/kép, akkor futtatni kell az infrát
                        if (file != "README.md" && !file.endsWith(".png") && file != "INIT_BUILD" && file != "") {
                            onlyDocs = false
                            break
                        }
                    }
                    
                    if (onlyDocs) {
                        echo "--- CSAK DOKUMENTÁCIÓ VÁLTOZOTT ---"
                        env.IS_ONLY_DOCS = "true"
                    } else {
                        echo "--- INFRASTRUKTÚRA VÁLTOZÁS ÉSZLELVE ---"
                        env.IS_ONLY_DOCS = "false"
                    }
                }
            }
        }

        stage('Terraform Init') {
            when { expression { env.IS_ONLY_DOCS != "true" } }
            steps {
                sh 'terraform init -input=false -force-copy'
            }
        }

        stage('Terraform Action') {
            when { expression { env.IS_ONLY_DOCS != "true" } }
            steps {
                script {
                    if (params.ACTION == 'apply') {
                        sh 'terraform apply --auto-approve'
                    } else {
                        sh 'terraform destroy --auto-approve'
                    }
                }
            }
        }

        stage('Ansible Provisioning') {
            when {
                allOf {
                    expression { env.IS_ONLY_DOCS != "true" }
                    expression { params.ACTION == 'apply' }
                }
            }
            steps {
                script {
                    def bastionIp = sh(script: "terraform output -raw bastion_ip", returnStdout: true).trim()
                    def webPrivateIp = sh(script: "terraform output -raw web_private_ip", returnStdout: true).trim()
                    def jenkinsKey = "/var/jenkins_home/id_rsa"
                    
                    echo "Waiting for infrastructure to be ready..."
                    sleep 30

                    sh """
                        ansible-playbook -i ${webPrivateIp}, \
                        --private-key ${jenkinsKey} \
                        -u ec2-user \
                        --ssh-common-args="-o StrictHostKeyChecking=no -o ProxyCommand='ssh -W %h:%p -q ec2-user@${bastionIp} -i ${jenkinsKey} -o StrictHostKeyChecking=no'" \
                        setup.yml
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                if (env.IS_ONLY_DOCS != "true") {
                    def status = currentBuild.result == 'SUCCESS' ? '✅ Sikeres!' : '❌ Hibás!'
                    discordSend description: "Művelet: ${params.ACTION} - Állapot: ${status}", 
                                title: "Project: ${JOB_NAME}", 
                                webhookURL: env.DISCORD_URL
                }
            }
        }
    }
}
