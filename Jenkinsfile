pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Válaszd ki a műveletet')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        DISCORD_URL           = credentials('DISCORD_WEBHOOK')
        // Itt definiálunk egy változót, ami megmondja, csak dokumentáció változott-e
        IS_ONLY_DOCS          = false 
    }

    stages {
        stage('Check Changes') {
            steps {
                script {
                    // Megnézzük, van-e bármi más változás a README-n kívül
                    def changes = sh(script: 'git diff --name-only HEAD~1 HEAD | grep -v "README.md" || true', returnStdout: true).trim()
                    if (changes == "") {
                        echo "Csak dokumentáció változott. Jelölés: SKIP_INFRA = true"
                        env.IS_ONLY_DOCS = "true"
                    }
                }
            }
        }

        stage('Terraform Init') {
            when { environment name: 'IS_ONLY_DOCS', value: 'false' }
            steps {
                sh 'terraform init -input=false -force-copy'
            }
        }

        stage('Terraform Action') {
            when { environment name: 'IS_ONLY_DOCS', value: 'false' }
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
                all {
                    environment name: 'IS_ONLY_DOCS', value: 'false'
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
                // Csak akkor küldünk Discord üzenetet, ha ténylegesen történt infra művelet
                if (env.IS_ONLY_DOCS == "false") {
                    def status = currentBuild.result == 'SUCCESS' ? '✅ Sikeres!' : '❌ Hibás!'
                    discordSend description: "Művelet: ${params.ACTION} - Állapot: ${status}", 
                                title: "Project: ${JOB_NAME}", 
                                webhookURL: env.DISCORD_URL
                }
            }
        }
    }
}
