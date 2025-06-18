# AWS IAM Permissions Required for User Story 1.2: Foundational Networking

## **Minimal Permissions Policy for VPC and Networking**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VPCManagement",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVpc",
                "ec2:DeleteVpc",
                "ec2:DescribeVpcs",
                "ec2:ModifyVpcAttribute",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DescribeTags"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:vpc/*"
            ]
        },
        {
            "Sid": "SubnetManagement", 
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSubnet",
                "ec2:DeleteSubnet",
                "ec2:DescribeSubnets",
                "ec2:ModifySubnetAttribute"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:subnet/*"
            ]
        },
        {
            "Sid": "InternetGatewayManagement",
            "Effect": "Allow", 
            "Action": [
                "ec2:CreateInternetGateway",
                "ec2:DeleteInternetGateway",
                "ec2:DescribeInternetGateways",
                "ec2:AttachInternetGateway",
                "ec2:DetachInternetGateway"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:internet-gateway/*",
                "arn:aws:ec2:*:*:vpc/*"
            ]
        },
        {
            "Sid": "RouteTableManagement",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateRouteTable",
                "ec2:DeleteRouteTable", 
                "ec2:DescribeRouteTables",
                "ec2:CreateRoute",
                "ec2:DeleteRoute",
                "ec2:AssociateRouteTable",
                "ec2:DisassociateRouteTable"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:route-table/*",
                "arn:aws:ec2:*:*:subnet/*",
                "arn:aws:ec2:*:*:internet-gateway/*"
            ]
        },
        {
            "Sid": "AvailabilityZoneInfo",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAvailabilityZones"
            ],
            "Resource": "*"
        },
        {
            "Sid": "S3BackupBucketManagement",
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:Get*",
                "s3:PutBucketVersioning",
                "s3:PutBucketEncryption",
                "s3:PutBucketTagging",
                "s3:PutBucketLifecycleConfiguration",
                "s3:PutBucketPublicAccessBlock",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws:s3:::xpress-erpnext-app-backups-*",
                "arn:aws:s3:::xpress-erpnext-app-backups-*/*"
            ]
        }
    ]
}
```

## **Summary of Required Permissions by Service:**

### **EC2 (VPC/Networking)**
- **VPC**: Create, delete, describe, modify attributes, tag management
- **Subnets**: Create, delete, describe, modify attributes  
- **Internet Gateway**: Create, delete, describe, attach/detach to VPC
- **Route Tables**: Create, delete, describe, create/delete routes, associate/disassociate
- **Availability Zones**: Read-only access to get AZ information

### **S3 (Application Backups)**
- **Bucket Management**: Create, delete, get properties
- **Bucket Configuration**: Versioning, encryption, tagging, lifecycle, public access block
- **Object Management**: Put, get, delete objects, list bucket contents

## **Resource Scope Restrictions:**

- **VPC Resources**: Scoped to VPCs, subnets, IGWs, and route tables (no wildcard on account)
- **S3 Resources**: Limited to `xpress-erpnext-app-backups-*` buckets only
- **AZ Information**: Required wildcard for read-only AZ data

## **Security Notes:**

1. **No SSH/Security Group permissions** - Not needed for User Story 1.2
2. **No EC2 instance permissions** - Will be added in User Story 1.3
3. **No IAM permissions** - Will be added in User Story 1.3 for instance roles
4. **Minimal S3 scope** - Only backup buckets, not terraform state buckets

## **Total New Permissions:**
- **EC2**: ~15 new permissions for networking
- **S3**: Reusing existing permissions from User Story 1.1

These permissions are the absolute minimum required for User Story 1.2 implementation.
