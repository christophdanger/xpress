# **Product Requirements Document:**

# **EC2 Staging Environment for ERPNext**

## **1\. Overview**

### **1.1. Objective**

The objective is to use Infrastructure as Code (IaC) and CI/CD to deploy a cost-effective, self-contained, and reproducible **staging environment** for the Frappe/ERPNext application on a single Amazon EC2 instance. This architecture prioritizes simplicity and low operational cost while establishing a clear and simple migration path to a more scalable architecture in the future. It serves as an ideal environment for development, testing, or small-scale production use cases.

### **1.2. Target Persona**

This document is intended for a DevOps Engineer, a Solutions Architect, or an advanced LLM Coding Assistant tasked with generating the necessary code and configuration to realize the architecture.

### **1.3. Success Criteria**

This phase is complete when:

* The AWS infrastructure, consisting of a single EC2 instance and its related resources, is defined in Terraform and successfully provisioned.  
* A GitHub Actions workflow automatically connects to the EC2 instance to pull the latest code, rebuilds the Docker containers, and runs database migrations upon a push to the develop branch.  
* A functional ERPNext instance is accessible via a secure HTTPS endpoint, with all services (application, database, cache) running as containers on the single EC2 instance.  
* An automated backup process is in place, regularly storing application data in a secure, off-instance location.

## **2\. Core Technologies**

* **Infrastructure as Code:** Terraform 1  
* **CI/CD:** GitHub Actions 3  
* **Containerization:** Docker, Docker Compose, using the frappe\_docker project 5  
* **Cloud Platform:** Amazon Web Services (AWS)  
* **Core AWS Services:** EC2, EBS, S3 (for backups), IAM, VPC, Systems Manager (SSM)

## **3\. Functional Requirements (Epics & User Stories)**

### **Epic 1: Infrastructure as Code (IaC) with Terraform**

Provision the complete, cost-effective AWS architecture for a staging environment on a single EC2 instance.

* **User Story 1.1: Secure Terraform State Backend**  
  * **As a** DevOps engineer, **I want** to configure a secure remote backend for Terraform state **so that** state is managed centrally, securely, and collaboratively.  
  * **Acceptance Criteria:**  
    * An S3 bucket is created to store the terraform.tfstate file.  
    * The S3 bucket must have versioning and server-side encryption enabled.  
    * A DynamoDB table is created for state locking to prevent concurrent modifications.1  
* **User Story 1.2: Foundational Networking (VPC)**  
  * **As a** DevOps engineer, **I want** to provision a simple Virtual Private Cloud (VPC) **so that** the application has a secure and isolated network environment.  
  * **Acceptance Criteria:**  
    * The VPC is defined with a non-default CIDR block.  
    * It contains a single public subnet.  
    * An Internet Gateway (IGW) is attached to the VPC, and the public subnet's route table has a route to it.  
* **User Story 1.3: Self-Contained EC2 Instance**  
  * **As a** DevOps engineer, **I want** to provision a single, self-contained EC2 instance to host the entire containerized application stack **so that** I can minimize cost and management complexity.  
  * **Acceptance Criteria:**  
    1. **Instance:**  
       * A single EC2 instance is provisioned (e.g., a burstable t4g.medium or t3.medium instance is a suitable starting point).1  
       * An Elastic IP address is allocated and associated with the instance for a static public IP.  
    2. **Storage:**  
       * An Amazon EBS volume of type gp3 is created and attached to the instance to provide persistent storage for all Docker volumes.  
    3. **Security & Access:**  
       * A Security Group is configured to allow inbound traffic on port 80 (HTTP) and 443 (HTTPS) from anywhere (0.0.0.0/0).  
       * Inbound traffic on port 22 (SSH) is denied by default.  
       * An IAM role with the AmazonSSMManagedInstanceCore policy is attached to the instance, enabling secure shell access via AWS Systems Manager Session Manager.7

### **Epic 2: Automated Deployment & Configuration**

Create a fully automated pipeline to deploy and configure the Frappe/ERPNext application on the EC2 instance.

* **User Story 2.1: Automated Application Deployment**  
  * **As a** developer, **I want** a CI/CD pipeline to automatically deploy my code changes to the EC2 instance **so that** my updates are reflected without manual intervention.  
  * **Acceptance Criteria:**  
    * A GitHub Actions workflow is configured to trigger on a push to the develop branch.3  
    * The workflow securely connects to the EC2 instance (e.g., using SSM Run Command).  
    * On the instance, the workflow pulls the latest code from the Git repository.  
    * It then executes docker compose \-f pwd.yml... up \-d \--build to rebuild the application image with the latest code and restart the container stack.5  
    * The pipeline executes docker compose exec backend bench migrate to apply any necessary database schema changes.9  
* **User Story 2.2: Automated SSL/TLS Configuration**  
  * **As an** operator, **I want** SSL/TLS to be automatically configured and renewed using Let's Encrypt **so that** the application is served securely over HTTPS.  
  * **Acceptance Criteria:**  
    * The deployment process uses the frappe\_docker overrides/compose.https.yaml file.  
    * A Traefik container is launched and configured to manage certificates based on environment variables (SITES, LETSENCRYPT\_EMAIL).11  
    * Traefik successfully obtains and installs a Let's Encrypt certificate, and automatically handles renewals.

### **Epic 3: Operational Readiness**

Ensure the single-server deployment is robust and recoverable.

* **User Story 3.1: Automated Backups to S3**  
  * **As an** operator, **I want** automated backups of the application database and files to be stored securely in Amazon S3 **so that** I can recover from data loss or instance failure.  
  * **Acceptance Criteria:**  
    * A cron job is configured on the host EC2 instance.13  
    * The cron job periodically executes docker compose exec backend bench \--site all backup \--with-files to create a backup within the container's persistent volume.13  
    * A script within the cron job then syncs the generated backup artifacts to a designated S3 bucket using the AWS CLI.  
    * The target S3 bucket is configured with versioning and a lifecycle policy to transition older backups to a lower-cost storage tier (e.g., S3 Glacier Instant Retrieval).

## **4\. Out of Scope for Phase 1**

* Production environment deployment and configuration.  
* High availability and automated failover.  
* Horizontal scaling of application components.  
* Use of managed services like RDS, ElastiCache, or EFS.  
* Advanced observability (distributed tracing, custom metric dashboards).  
* Performance and load testing.