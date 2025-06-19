# Reference Implementation Templates

This directory contains templates for various components that can be used in ERPNext/Frappe deployments. These templates are designed to be copied and customized for your specific projects.

## Directory Structure

### `/github-actions/`
Contains GitHub Actions workflow templates for automated deployment, monitoring, and maintenance of ERPNext on AWS EC2.

## How to Use These Templates

1. **Copy to your project**: Copy the template files you need to your project repository
2. **Remove .template extension**: Rename files to remove the `.template` suffix
3. **Customize**: Update the templates with your specific configuration values
4. **Test**: Validate the templates work in your environment before production use

## Important Notes

- **Reference Implementation**: This repository serves as a reference implementation library, not a direct deployment repository
- **Templates Only**: All files in this directory are templates and do not run automatically in this repository
- **Customization Required**: Templates must be customized with your specific environment details before use
- **Testing Recommended**: Always test templates in a development environment first

## Contributing

When contributing new templates:
1. Ensure they follow the same naming convention (`.template` suffix)
2. Include comprehensive documentation
3. Test templates in multiple scenarios
4. Follow security best practices
5. Keep templates generic enough to be reusable

## Support

For questions about using these templates:
1. Review the documentation in each template directory
2. Check the main repository README for setup instructions
3. Refer to the infrastructure documentation in `/iac/aws/ec2/terraform/docs/`
