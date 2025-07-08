# Amazon MemoryDB Templates

Amazon MemoryDB for Redis is a fully managed, Redis-compatible database service that provides ultra-fast performance with microsecond read latency, single-digit millisecond write latency, and high throughput.

## Templates

### MemoryDBMultiRegionCluster.yaml
Creates a MemoryDB cluster with:
- Redis 7 compatibility
- High availability configuration
- VPC with private subnets
- Parameter group for optimization
- User and ACL management
- TLS encryption enabled
- Comprehensive monitoring setup

## Key Benefits

- **Ultra-Fast Performance**: Microsecond read latency and single-digit millisecond write latency
- **Durability**: Multi-AZ with automatic failover and data persistence
- **Redis Compatibility**: Works with existing Redis applications and tools
- **Fully Managed**: Automated patching, backups, and monitoring
- **Security**: Encryption in transit and at rest, IAM integration
- **Scalability**: Scale up to 500 nodes per cluster

## Architecture

The template creates:
- VPC with private subnets across multiple AZs
- MemoryDB subnet group for network isolation
- Parameter group with optimized settings
- User authentication with password-based access
- Access Control List (ACL) for fine-grained permissions
- Security groups with appropriate rules

## Prerequisites

- AWS CLI configured with appropriate permissions
- VPC with at least 2 private subnets in different AZs
- Understanding of Redis commands and data structures
- Password for admin user (minimum 16 characters)

## Cost Optimization

### Pricing Components:
- **Node Hours**: Based on node type and running time
- **Data Transfer**: Between AZs and regions
- **Backup Storage**: For automated backups beyond retention period

### Cost Optimization Tips:
- Choose appropriate node types based on workload requirements
- Use reserved instances for predictable workloads
- Monitor memory utilization and right-size nodes
- Implement data expiration policies
- Use compression for large values
- Consider data tiering for cost-effective storage

### Node Type Recommendations:
- **db.r7g.large**: Development and testing (2 vCPUs, 16 GB RAM)
- **db.r7g.xlarge**: Small production workloads (4 vCPUs, 32 GB RAM)
- **db.r7g.2xlarge**: Medium production workloads (8 vCPUs, 64 GB RAM)

## Security Best Practices

- **Network Security**: Deploy in private subnets with security groups
- **Encryption**: Enable TLS for data in transit
- **Authentication**: Use strong passwords and rotate regularly
- **Access Control**: Implement least privilege with ACLs
- **Monitoring**: Enable CloudWatch logs and metrics
- **Compliance**: Use AWS Config for compliance monitoring

## Deployment

### Basic Deployment
```bash
aws cloudformation create-stack \
  --stack-name my-memorydb-cluster \
  --template-body file://MemoryDBMultiRegionCluster.yaml \
  --parameters ParameterKey=ClusterName,ParameterValue=prod-cache-cluster \
               ParameterKey=NodeType,ParameterValue=db.r7g.xlarge \
               ParameterKey=NumShards,ParameterValue=2 \
               ParameterKey=AdminPassword,ParameterValue=MySecurePassword123! \
  --region us-west-2
```

### Verify Deployment
```bash
# Check cluster status
aws memorydb describe-clusters --cluster-name prod-cache-cluster

# List cluster endpoints
aws memorydb describe-clusters \
  --cluster-name prod-cache-cluster \
  --query 'Clusters[0].ClusterEndpoint'
```

## Connecting to MemoryDB

### Using Redis CLI
```bash
# Install redis-cli
sudo yum install redis6 -y

# Connect with TLS (replace endpoint with your cluster endpoint)
redis-cli -h clustercfg.prod-cache-cluster.xxxxxx.memorydb.us-west-2.amazonaws.com \
  -p 6379 \
  --tls \
  --cert /path/to/redis-client-cert.crt \
  --key /path/to/redis-client-key.key \
  --cacert /path/to/redis-ca-cert.crt \
  -a MySecurePassword123!
```

### Using Python (redis-py)
```python
import redis
import ssl

# Create SSL context
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

# Connect to MemoryDB
r = redis.Redis(
    host='clustercfg.prod-cache-cluster.xxxxxx.memorydb.us-west-2.amazonaws.com',
    port=6379,
    password='MySecurePassword123!',
    ssl=True,
    ssl_context=ssl_context,
    decode_responses=True
)

# Test connection
r.ping()
print("Connected to MemoryDB!")

# Basic operations
r.set('key1', 'value1')
print(r.get('key1'))
```

### Using Node.js (ioredis)
```javascript
const Redis = require('ioredis');

const redis = new Redis({
  host: 'clustercfg.prod-cache-cluster.xxxxxx.memorydb.us-west-2.amazonaws.com',
  port: 6379,
  password: 'MySecurePassword123!',
  tls: {
    rejectUnauthorized: false
  }
});

redis.on('connect', () => {
  console.log('Connected to MemoryDB!');
});

// Basic operations
redis.set('key1', 'value1');
redis.get('key1').then(result => {
  console.log(result);
});
```

## Performance Optimization

### Memory Management
```redis
# Configure memory policy
CONFIG SET maxmemory-policy allkeys-lru

# Monitor memory usage
INFO memory

# Check key expiration
TTL mykey
```

### Connection Pooling
```python
import redis.connection

# Configure connection pool
pool = redis.ConnectionPool(
    host='your-cluster-endpoint',
    port=6379,
    password='your-password',
    ssl=True,
    max_connections=20,
    retry_on_timeout=True
)

r = redis.Redis(connection_pool=pool)
```

## Monitoring and Observability

### CloudWatch Metrics
Key metrics to monitor:
- **CPUUtilization**: Node CPU usage
- **DatabaseMemoryUsagePercentage**: Memory utilization
- **NetworkBytesIn/Out**: Network traffic
- **CurrConnections**: Active connections
- **Evictions**: Key evictions due to memory pressure
- **CacheHits/CacheMisses**: Cache efficiency

### CloudWatch Alarms
```bash
# Create CPU utilization alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "MemoryDB-HighCPU" \
  --alarm-description "MemoryDB CPU utilization is high" \
  --metric-name CPUUtilization \
  --namespace AWS/MemoryDB \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=ClusterName,Value=prod-cache-cluster \
  --evaluation-periods 2
```

### Logging
```bash
# Enable slow log
CONFIG SET slowlog-log-slower-than 10000
CONFIG SET slowlog-max-len 128

# View slow log
SLOWLOG GET 10
```

## Backup and Recovery

### Automated Backups
```bash
# Create snapshot
aws memorydb create-snapshot \
  --cluster-name prod-cache-cluster \
  --snapshot-name prod-cache-backup-$(date +%Y%m%d)
```

### Point-in-Time Recovery
```bash
# Restore from snapshot
aws memorydb create-cluster \
  --cluster-name restored-cluster \
  --snapshot-name prod-cache-backup-20240101 \
  --node-type db.r7g.large
```

## Troubleshooting

### Common Issues:
1. **Connection Timeouts**: Check security groups and network ACLs
2. **High Memory Usage**: Implement expiration policies and optimize data structures
3. **Performance Issues**: Monitor slow log and optimize queries
4. **Authentication Failures**: Verify user credentials and ACL permissions

### Diagnostic Commands:
```bash
# Check cluster health
aws memorydb describe-clusters --cluster-name prod-cache-cluster

# View cluster events
aws memorydb describe-events --source-identifier prod-cache-cluster

# Check parameter group settings
aws memorydb describe-parameter-groups --parameter-group-name prod-cache-params

# Monitor real-time metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/MemoryDB \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=prod-cache-cluster \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Average
```

### Redis Commands for Troubleshooting:
```redis
# Check server info
INFO server

# Monitor commands in real-time
MONITOR

# Check memory usage
MEMORY USAGE mykey

# Analyze key patterns
SCAN 0 MATCH pattern:* COUNT 100
```

## Best Practices

### Data Modeling
- Use appropriate data structures (strings, hashes, lists, sets, sorted sets)
- Implement proper key naming conventions
- Set appropriate TTL values for temporary data
- Use pipelining for bulk operations

### Performance
- Use connection pooling in applications
- Implement proper error handling and retries
- Monitor and optimize slow queries
- Use Redis Cluster for horizontal scaling

### Security
- Rotate passwords regularly
- Use IAM authentication where possible
- Implement network segmentation
- Enable audit logging

## Cleanup

```bash
# Delete snapshots first
aws memorydb delete-snapshot --snapshot-name prod-cache-backup-20240101

# Delete the CloudFormation stack
aws cloudformation delete-stack --stack-name my-memorydb-cluster

# Verify deletion
aws cloudformation describe-stacks --stack-name my-memorydb-cluster
```

## Additional Resources

- [MemoryDB Documentation](https://docs.aws.amazon.com/memorydb/)
- [Redis Documentation](https://redis.io/documentation)
- [MemoryDB Best Practices](https://docs.aws.amazon.com/memorydb/latest/devguide/best-practices.html)
- [Redis Commands Reference](https://redis.io/commands)
- [AWS MemoryDB Pricing](https://aws.amazon.com/memorydb/pricing/)
