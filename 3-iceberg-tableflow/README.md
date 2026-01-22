# Iceberg Tableflow Configuration

This directory contains Terraform configuration to enable Confluent Tableflow on a Kafka topic (transaction enriched) for automatic Iceberg table materialization.

## Overview

Tableflow automatically manages Iceberg tables from Kafka topics, materializing them in S3 without requiring manual Flink jobs. This setup enables Tableflow on a single topic.

## Directory Structure

```
iceberg-tableflow/
├── README.md          # This file
└── IaC/               # Terraform configuration
    ├── providers.tf    # Terraform providers
    ├── variables.tf    # Input variables
    ├── data.tf         # Data sources (remote state)
    ├── tableflow.tf    # Tableflow resource configuration
    ├── outputs.tf     # Output values
    ├── terraform.tfvars.example  # Example variables file
    └── README.md       # Detailed usage instructions
```

## Quick Start

1. Navigate to the IaC directory:
   ```bash
   cd IaC
   ```

2. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Configure your variables (see `IaC/README.md` for details)

4. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

For detailed instructions, see [IaC/README.md](./IaC/README.md).