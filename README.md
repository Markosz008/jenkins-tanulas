AWS Infrastructure Automation with Jenkins, Terraform & Ansible
This repository demonstrates a complete GitOps and CI/CD pipeline that automates the provisioning and configuration of cloud infrastructure on AWS.

🏗️ Architecture Overview
The pipeline follows a modern DevOps workflow to deploy a functional web server from scratch:

Infrastructure as Code (Terraform):

Networking: Custom VPC, Public Subnet, Internet Gateway, and Route Tables.

Security: Security Groups with strictly defined ingress rules for SSH (Port 22) and HTTP (Port 80).

Compute: AWS EC2 instance (t3.micro) running Amazon Linux 2023.

State Management: Remote state storage using AWS S3 with encryption for team collaboration and security.

Configuration Management (Ansible):

Automated software provisioning via SSH.

Installation and service management of the Apache (httpd) web server.

Automated deployment of custom web content.

Orchestration (Jenkins Pipeline):

A declarative pipeline managing the entire lifecycle.

Secure credential handling for AWS and SSH keys.

Real-time notifications: Integrated Discord webhooks for build status updates.

🚀 The Pipeline Flow
Checkout: Pulls the latest code from GitHub.

Terraform Init & Plan: Initializes the backend and previews infrastructure changes.

Terraform Apply: Provisions the AWS resources.

Ansible Provisioning:

Dynamically retrieves the EC2 Public IP.

Sets correct permissions for the SSH deploy key.

Configures the remote server once it becomes reachable.

Post-Build: Sends success/failure notifications to Discord.

💡 Key Challenges Solved
Dynamic AMI Selection: Handled region-specific AMI ID requirements for eu-central-1.

Permission Handling: Resolved Docker-to-Host filesystem permission issues for SSH private keys using workspace workarounds.

Networking & Security: Implemented proper Security Group rules to bridge the gap between a running instance and a reachable web service.

🌐 Final Result
The project results in a fully accessible web server deployed at a public AWS IP address, configured entirely through code without any manual intervention in the AWS Console.

How to use
Ensure your AWS credentials are added to Jenkins.

Update the bucket name in main.tf to your unique S3 bucket.

Trigger the Jenkins job.

Happy Automating! 🛠️
📸 Screenshot
<img width="1722" height="478" alt="Képernyőfotó 2026-05-06 - 12 32 22" src="https://github.com/user-attachments/assets/ff1ff397-480e-44ac-9a4b-04f33eba9793" />
