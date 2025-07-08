# Amazon Q Business Templates

Amazon Q Business is an enterprise AI assistant that helps organizations unlock insights from their data and documents.

## Templates

### QBusinessApplication.yaml
Creates a basic Q Business application with:
- Service role with proper permissions
- Identity Center integration
- Attachments and Q Apps enabled
- Development environment tags

## Prerequisites

- AWS IAM Identity Center must be enabled in your account
- Obtain the Identity Center instance ARN from the console

## Cost Optimization

- Q Business pricing is per user per month
- Start with a small pilot group
- Monitor usage through CloudWatch metrics
- Consider data source costs separately

## Security Best Practices

- Uses service-linked roles for secure access
- Integrates with Identity Center for authentication
- Enables attachment controls for document security
- Tags resources for governance

## Deployment

```bash
aws cloudformation create-stack \
  --stack-name my-qbusiness-app \
  --template-body file://QBusinessApplication.yaml \
  --parameters ParameterKey=IdentityCenterInstanceArn,ParameterValue=arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxxxxx \
  --capabilities CAPABILITY_IAM
```