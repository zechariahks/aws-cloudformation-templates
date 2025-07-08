# Amazon DSQL Templates

Amazon DSQL is a serverless, distributed SQL database designed for high-scale applications with automatic scaling and built-in high availability.

## Templates

### DSQLCluster.yaml
Creates a basic DSQL cluster with:
- Serverless configuration
- Primary endpoint for connections
- Optional deletion protection
- Cost optimization tags

## Cost Optimization

- DSQL charges based on:
  - Data Processing Units (DPUs) consumed
  - Storage used
  - Data transfer
- No upfront costs or minimum fees
- Automatic scaling reduces idle costs

## Security Best Practices

- Use IAM authentication for database access
- Enable deletion protection for production
- Implement least privilege access policies
- Monitor access through CloudTrail

## Deployment

```bash
aws cloudformation create-stack \
  --stack-name my-dsql-cluster \
  --template-body file://DSQLCluster.yaml \
  --parameters ParameterKey=DeletionProtection,ParameterValue=true
```