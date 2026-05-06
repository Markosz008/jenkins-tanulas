# AWS Infrastructure Automation with Jenkins & Terraform

This project demonstrates a professional CI/CD pipeline for deploying AWS infrastructure using Infrastructure as Code (IaC) principles.

## 🚀 Features
- **Automated VPC Deployment:** Uses Terraform to provision a Virtual Private Cloud on AWS.
- **Remote State Management:** Implements an S3 Backend to store Terraform state securely and prevent resource duplication.
- **Jenkins Pipeline:** A fully automated pipeline that handles Init, Plan, and Apply stages.
- **Discord Integration:** Real-time notifications for build success or failure.

## 🛠 Tech Stack
- **Cloud:** AWS (VPC, S3, IAM)
- **IaC:** Terraform
- **CI/CD:** Jenkins (running in Docker)
- **Messaging:** Discord Webhooks

## 🏗 Architecture
1. **GitHub:** Triggered on code push.
2. **Jenkins:** Pulls the code and injects AWS credentials.
3. **Terraform:** Connects to the S3 bucket for state synchronization.
4. **AWS:** Provisions the networking infrastructure.
5. **Discord:** Sends a status report to the developer.

<img width="1722" height="478" alt="Képernyőfotó 2026-05-06 - 12 32 22" src="https://github.com/user-attachments/assets/ff1ff397-480e-44ac-9a4b-04f33eba9793" />
