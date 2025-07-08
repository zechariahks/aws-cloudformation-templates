# Amazon EKS Auto Mode Templates

Amazon EKS Auto Mode simplifies Kubernetes cluster management by automatically provisioning and managing compute resources, eliminating the need to manually configure node groups.

## Templates

### EKSAutoModeCluster.yaml
Creates an EKS cluster with Auto Mode featuring:
- Automatic node provisioning and scaling
- Complete VPC setup with public/private subnets
- Proper IAM roles for cluster and nodes
- Block storage configuration
- API and ConfigMap authentication mode
- Bootstrap cluster creator admin permissions

## Key Benefits of Auto Mode

- **Simplified Management**: No need to manage node groups, launch templates, or Auto Scaling groups
- **Cost Optimization**: Automatic right-sizing and scaling based on workload demands
- **Enhanced Security**: Managed security updates and patching
- **Improved Reliability**: Built-in high availability and fault tolerance

## Architecture

The template creates:
- VPC with public and private subnets across 2 AZs
- Internet Gateway and routing for public subnets
- EKS cluster with Auto Mode enabled
- IAM roles with least privilege permissions
- Security groups with proper ingress/egress rules

## Prerequisites

- AWS CLI configured with appropriate permissions
- kubectl installed for cluster management
- Sufficient service quotas for EKS and EC2

## Cost Optimization

- **Cluster Cost**: $0.10 per hour for the EKS cluster
- **Compute Cost**: Pay only for EC2 instances that Auto Mode provisions
- **Storage Cost**: EBS volumes are charged separately
- **Data Transfer**: Standard AWS data transfer rates apply

### Cost Optimization Tips:
- Use Spot instances where appropriate (Auto Mode handles this automatically)
- Monitor resource utilization with Container Insights
- Implement Horizontal Pod Autoscaler (HPA) and Vertical Pod Autoscaler (VPA)
- Use AWS Cost Explorer to track spending

## Security Best Practices

- **IAM Roles**: Separate roles for cluster and nodes with minimal required permissions
- **Network Security**: Private subnets for worker nodes, public subnets for load balancers
- **Authentication**: API and ConfigMap mode for flexible access control
- **Encryption**: Enable encryption at rest and in transit
- **Pod Security**: Implement Pod Security Standards
- **Network Policies**: Use Kubernetes Network Policies for micro-segmentation

## Deployment

### Basic Deployment
```bash
aws cloudformation create-stack \
  --stack-name my-eks-auto-cluster \
  --template-body file://EKSAutoModeCluster.yaml \
  --parameters ParameterKey=ClusterName,ParameterValue=my-production-cluster \
               ParameterKey=KubernetesVersion,ParameterValue=1.31 \
  --capabilities CAPABILITY_IAM \
  --region us-west-2
```

### Configure kubectl
```bash
aws eks update-kubeconfig --region us-west-2 --name my-production-cluster
```

### Verify Cluster
```bash
kubectl get nodes
kubectl get pods -A
```

## Post-Deployment Configuration

### Install AWS Load Balancer Controller
```bash
# Create IAM role for AWS Load Balancer Controller
eksctl create iamserviceaccount \
  --cluster=my-production-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --override-existing-serviceaccounts \
  --approve

# Install the controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-production-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Enable Container Insights
```bash
curl -s https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/my-production-cluster/;s/{{region_name}}/us-west-2/" | kubectl apply -f -
```

## Monitoring and Observability

- **CloudWatch Container Insights**: Monitor cluster and application metrics
- **AWS X-Ray**: Distributed tracing for applications
- **Prometheus and Grafana**: Open-source monitoring stack
- **Fluent Bit**: Log aggregation and forwarding

## Troubleshooting

### Common Issues:
1. **Insufficient Permissions**: Ensure IAM roles have required policies
2. **Subnet Configuration**: Verify subnets have proper tags for load balancer discovery
3. **Security Groups**: Check ingress/egress rules for connectivity issues
4. **Resource Quotas**: Monitor service limits and request increases if needed

### Useful Commands:
```bash
# Check cluster status
aws eks describe-cluster --name my-production-cluster

# View cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check node status
kubectl describe nodes

# View Auto Mode configuration
aws eks describe-cluster --name my-production-cluster --query 'cluster.computeConfig'
```

## Cleanup

```bash
# Delete the CloudFormation stack
aws cloudformation delete-stack --stack-name my-eks-auto-cluster

# Verify deletion
aws cloudformation describe-stacks --stack-name my-eks-auto-cluster
```

## Additional Resources

- [EKS Auto Mode Documentation](https://docs.aws.amazon.com/eks/latest/userguide/auto-mode.html)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Workshop](https://www.eksworkshop.com/)
