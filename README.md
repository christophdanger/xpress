# xspress
An easy way to deliver the Frappe Framework to common IaaS, PaaS, and local systems.

## Overview

xpress is a set of tooling to deliver, setup, and maintain infrastructure and configuration for hosting [Frappe Framework] based applications (like ERPNext). .

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

## Contributing

Contributing to this project is easy and straightforward. Simply follow these steps:

1. Fork the repository to your own GitHub account.
2. Clone the forked repository to your local machine.
3. Create a new branch for your changes.
4. Make the necessary modifications and improvements.
5. Commit your changes with descriptive commit messages.
6. Push the changes to your forked repository.
7. Submit a pull request from your branch to the main repository.
8. The maintainers will review your pull request and provide feedback if needed.
9. Once your changes are approved, they will be merged into the main codebase.
