# IAM Policy for User Story 1.3: Self-Contained EC2 Instance

## Minimal Required Permissions

Based on the Terraform plan and current permission gaps, you need to create an IAM policy with the following permissions for the `xpress-dev` user to complete User Story 1.3:

### Policy Name: `XpressERPNextEC2Policy`

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EC2SecurityGroupManagement",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:DescribeSecurityGroups",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:CreateTags",
                "ec2:DescribeTags"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "us-east-1"
                }
            }
        },
        {
            "Sid": "EC2InstanceManagement",
            "Effect": "Allow",
            "Action": [
                "ec2:RunInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:RebootInstances",
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "us-east-1"
                }
            }
        },
        {
            "Sid": "EC2ImageAndVolumeAccess",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateVolume",
                "ec2:DeleteVolume",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ec2:ModifyVolumeAttribute"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "us-east-1"
                }
            }
        },
        {
            "Sid": "EC2NetworkingDescribe",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeRouteTables",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeNetworkInterfaces"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "us-east-1"
                }
            }
        }
    ]
}
```

## Alternative: Attach AWS Managed Policy

If you prefer to use AWS managed policies, you can attach:
- `AmazonEC2FullAccess` (broader permissions but simpler)

However, the custom policy above follows the **principle of least privilege** and only grants the specific permissions needed for User Story 1.3.

## Steps to Apply

1. **Go to AWS Console → IAM → Policies**
2. **Create Policy** → JSON tab
3. **Paste the above JSON**
4. **Name**: `XpressERPNextEC2Policy`
5. **Description**: "Minimal EC2 permissions for ERPNext User Story 1.3"
6. **Go to Users → xpress-dev → Permissions**
7. **Attach Policy** → Select `XpressERPNextEC2Policy`

## What This Policy Enables

✅ **Security Group Creation/Management** - For ERPNext security group
✅ **EC2 Instance Management** - Create, start, stop, terminate instances  
✅ **EBS Volume Management** - For encrypted root volumes
✅ **AMI Access** - To launch instances from Amazon Linux 2 AMI
✅ **Network Resource Describe** - To validate VPC/subnet integration
✅ **Tagging** - For proper resource organization

## Security Features

🔒 **Region Restricted** - Only allows actions in us-east-1
🔒 **Principle of Least Privilege** - Only required actions
🔒 **No IAM Permissions** - Cannot modify user/role permissions
🔒 **No Billing Access** - Cannot view or modify billing

After you apply this policy, we can continue with `terraform apply` for User Story 1.3!
