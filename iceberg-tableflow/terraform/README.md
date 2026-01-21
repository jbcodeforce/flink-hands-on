# Tableflow Configuration for Transaction Enriched Topic

This Terraform configuration enables Confluent Tableflow on a single Kafka topic (transaction enriched) to automatically materialize it as an Iceberg table in S3.

## Overview

Tableflow automatically manages Iceberg tables from Kafka topics. This configuration enables Tableflow on the `transaction_enriched` topic (or any topic you specify).

## Prerequisites

1. **Confluent Cloud Account** with:
   - An environment
   - A Kafka cluster
   - Tableflow provider integration configured (BYOB AWS)
   - S3 bucket for Iceberg storage
   - Tableflow API key and secret

2. **Terraform** >= 1.3.0

3. **Confluent Cloud API Credentials**:
   ```bash
   export CONFLUENT_CLOUD_API_KEY="your-api-key"
   export CONFLUENT_CLOUD_API_SECRET="your-api-secret"
   ```

## Configuration Options

### Option 1: Use Remote State from IaC (Recommended)

If you have an existing IaC setup that outputs the required values:

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Set the path to your IaC state file:
   ```hcl
   iac_state_path = "../../IaC/terraform.tfstate"
   ```

3. Configure the topic name:
   ```hcl
   topic_name = "tx_enriched"
   ```

The configuration will automatically read:
- `confluent_environment_id`
- `kafka_cluster_id`
- `s3_bucket_name`
- `tableflow_provider_integration_id`
- `tableflow_api_key`
- `tableflow_api_secret`

### Option 2: Direct Configuration

If you're not using remote state, provide all values directly:

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Set `iac_state_path` to empty string:
   ```hcl
   iac_state_path = ""
   ```

3. Fill in all required variables:
   ```hcl
   confluent_environment_id = "env-xxxxx"
   kafka_cluster_id         = "lkc-xxxxx"
   s3_bucket_name           = "my-iceberg-bucket"
   tableflow_provider_integration_id = "cpi-xxxxx"
   tableflow_api_key        = "xxxxx"
   tableflow_api_secret     = "xxxxx"
   topic_name               = "transaction_enriched"
   ```

## Usage


```bash
# initialize Terraform
terraform init
# 
terraform plan
terraform apply
terraform output
```

## Important Notes

- **Topic Schema**: The topic must have a schema registered in Schema Registry before Tableflow can materialize it. If the topic is created by Flink DDL statements, ensure those are deployed first.

- **Dependencies**: Tableflow requires:
  - The topic to exist
  - Schema to be registered for the topic
  - S3 bucket with proper permissions
  - Tableflow provider integration configured

- **Topic Creation**: This configuration does not create the Kafka topic. The topic must exist before enabling Tableflow. If your topic is created by Flink, ensure Flink statements are deployed first.

## Outputs

After applying, you can view outputs:

```bash
terraform output
```

Available outputs:
- `tableflow_enabled`: Whether Tableflow is enabled
- `tableflow_topic_name`: The topic name with Tableflow enabled
- `tableflow_topic_id`: The Tableflow topic resource ID
- `s3_bucket_name`: S3 bucket used for Iceberg storage
- `tableflow_provider_integration_id`: Provider integration ID

## Troubleshooting

### Error: Topic not found
- Ensure the topic exists in your Kafka cluster
- Verify the topic name is correct

### Error: Schema not found
- Register a schema for the topic in Schema Registry
- If using Flink, ensure DDL statements are deployed first

### Error: Provider integration not found
- Verify the provider integration ID is correct
- Ensure the provider integration is configured in Confluent Cloud

### Error: S3 bucket access denied
- Verify the IAM role used by the provider integration has S3 permissions
- Check bucket name is correct

## Reference

Based on the implementation from `cc-cdc-tx-demo`, this configuration provides a simplified setup for enabling Tableflow on a single topic.
