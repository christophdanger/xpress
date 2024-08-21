# xspress
An easy way to deliver the Frappe Framework to common IaaS, PaaS, and local systems.

## IaaS

### AWS

Recommended architecture:

* **VPC**: A Virtual Private Cloud to host all resources.
* **EC2 Instances**: For running the application and MariaDB/Postgres database.
* **RDS**: Managed relational database service for MariaDB/Postgres.
* **S3**: For storing any static files or backups.
* **IAM Roles**: Appropriately scoped roles for security.
* **Security Groups**: For controlling inbound and outbound traffic.
* **ECS (optional)**: For running and managing Docker containers for Frappe benchmarks if needed.

### Azure

### GCP
