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
                    // Lekérjük az utolsó commit üzenetét
                    def commitMsg = sh(script: "git log -1 --pretty=%B", returnStdout: true).trim().toLowerCase()
                    echo "Commit üzenet: ${commitMsg}"

                    // Ha az üzenetben benne van a 'readme', 'docs' vagy '[skip ci]', akkor IS_ONLY_DOCS = true
                    if (commitMsg.contains("readme") || commitMsg.contains("docs") || commitMsg.contains("[skip ci]")) {
                        echo "--- DOKUMENTÁCIÓ MÓDOSÍTÁS VAGY SKIP JELZÉS ÉSZLELVE ---"
                        env.IS_ONLY_DOCS = "true"
                    } else {
                        echo "--- INFRASTRUKTÚRA MÓDOSÍTÁS ÉSZLELVE ---"
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
                    
                    echo "Várakozás az infrastruktúra készre jelentésére..."
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
                // Csak akkor küldünk értesítést, ha ténylegesen futott az infra folyamat
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
