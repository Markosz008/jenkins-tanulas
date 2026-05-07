# 🚀 Automated Scalable Web Stack on AWS

A professional CI/CD pipeline demonstrating a highly available and scalable Flask application deployed on AWS using **Terraform**, **Ansible**, and **Jenkins**.

## 🏗️ Architecture Overview
* **Networking:** Custom VPC with Public Subnet (Bastion Host) and Private Subnets (App & DB layers).
* **Load Balancing:** Application Load Balancer (ALB) as the single entry point for traffic distribution.
* **Auto Scaling:** Dynamic EC2 instance management for automated scaling and high availability.
* **Database:** Managed Amazon RDS (MySQL) for persistent data storage.
* **Automation:** Terraform (Infrastructure), Ansible (Configuration), and Jenkins (Orchestration).

## 🛠️ Lessons Learned & Troubleshooting

This project involved solving real-world DevOps challenges across multiple layers of the stack:

### 1. Networking & Connectivity
* **Issue:** 502 Bad Gateway at the Load Balancer level.
* **Resolution:** Performed log analysis on backend servers to identify application startup failures.
* **Method:** Utilized **SSH Agent Forwarding** via the Bastion host to securely access and debug instances in private subnets.

### 2. Permissions & Port Management
* **Issue:** `Permission denied` when binding to Port 80.
* **Resolution:** Linux restricts privileged ports (below 1024) to the root user. Configured Ansible to initiate the application using `sudo`.
* **Environment Preservation:** Implemented `sudo -E` to ensure that critical environment variables (database credentials) were preserved during privilege escalation.

### 3. Service Conflicts
* **Issue:** Port 80 was occupied by a legacy Apache (`httpd`) service.
* **Resolution:** Automated a cleanup process in Ansible using `yum remove httpd` and the `fuser -k 80/tcp` command to force-release the port.

### 4. CI/CD Orchestration (Jenkins)
* **Logic:** Implemented a parameterized pipeline for dynamic `apply` and `destroy` actions.
* **Lessons:** Learned that Jenkins requires an initial "learning" run to register new parameters from the `Jenkinsfile`.
* **Debugging:** Established the importance of remote log files (`/home/ec2-user/flask.log`) to detect failures outside the Jenkins console output.

## 📈 Final Result
The project resulted in a stable, "one-click" infrastructure that handles software dependencies, database migrations, and web traffic distribution automatically.

---
*Developed during the DevOps Journey - 2026*
