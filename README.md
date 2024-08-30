# xspress
An easy way to deliver the Frappe Framework to common IaaS, PaaS, and local systems.

## Overview

xspress is a set of tooling to deliver, setup, and maintain infrastructure and configuration for hosting [Frappe Framework](https://frappeframework.com/) based applications (like [ERPNext](https://erpnext.com/)).

The current minimum system requirements/packages can be found here on [Frappe's docs](https://github.com/frappe/bench/blob/develop/docs/installation.md#manual-install).

## Manual Install (referenced from Frappe's docs)
To manually install frappe/erpnext, you can follow this this wiki for Linux and this wiki for MacOS. It gives an excellent explanation about the stack. You can also follow the steps mentioned below:

1. Install Prerequisites
    * Python 3.6+
    * Node.js 12
    * Redis 5					(caching and realtime updates)
    * MariaDB 10.3 / Postgres 9.5			(to run database driven apps)
    * yarn 1.12+					(js dependency manager)
    * pip 15+					(py dependency manager)
    * cron 						(scheduled jobs)
    * wkhtmltopdf (version 0.12.5 with patched qt) 	(for pdf generation)
• Nginx 					(for production)

2. Install Bench

Install the latest bench using pip:

```
pip3 install frappe-bench
```

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
