# Troubleshooting Flink Statement Authentication

## 401 Unauthorized Error

If you encounter a `401 Unauthorized` error when creating a Flink statement, it's typically due to authentication/authorization issues with the Flink API credentials.

### Common Causes

1. **Flink API Key not owned by the Principal**
   - The Flink API key (`flink_api_key`) must be owned by the service account specified in `flink_principal_id`
   - Verify in Confluent Cloud: API Keys → Your Flink API Key → Owner should match `flink_principal_id`

2. **Principal lacks FlinkAdmin role**
   - The service account (`flink_principal_id`) must have `FlinkAdmin` role on the compute pool
   - Verify in Confluent Cloud: Access → Role Bindings → Check if `FlinkAdmin` role exists for the service account on the compute pool

3. **Flink API Key not scoped to Flink region**
   - The Flink API key must be created for the Flink region (not just Kafka cluster)
   - Verify the API key is scoped to the Flink region resource

4. **Incorrect credentials**
   - Double-check that `flink_api_key` and `flink_api_secret` are correct
   - Ensure there are no extra spaces or characters

### Verification Steps

1. **Check Flink API Key ownership:**
   ```bash
   # Using Confluent CLI
   confluent api-key list --resource lfcp-xxxxx --output json
   ```
   Verify the owner matches your `flink_principal_id`

2. **Check service account permissions:**
   ```bash
   # List role bindings for the service account
   confluent iam rbac role-binding list --principal User:sa-xxxxx
   ```
   Look for `FlinkAdmin` role on the compute pool

3. **Verify API key is for Flink region:**
   - In Confluent Cloud UI: Go to API Keys
   - Check that the key is associated with the Flink region, not just Kafka cluster

### Solution: Create Flink API Key Properly

If the API key is not set up correctly, create a new one:

1. **Using Confluent Cloud UI:**
   - Navigate to API Keys
   - Click "Add key"
   - Select "Flink API Key"
   - Choose the Flink region
   - Select the service account (matching `flink_principal_id`) as the owner
   - Save the key and secret

2. **Using Confluent CLI:**
   ```bash
   # Get Flink region ID
   confluent flink region list
   
   # Create API key for Flink region, owned by service account
   confluent api-key create \
     --resource <flink-region-id> \
     --service-account <flink_principal_id> \
     --description "Flink API Key for Terraform"
   ```

3. **Using Terraform (recommended):**
   See `create-flink-api-key.tf` example below

### Required Role Bindings

Ensure the service account has:
- `FlinkAdmin` role on the compute pool
- Optionally: `EnvironmentAdmin` role on the environment (for broader access)

### Example: Creating Flink API Key with Terraform

```terraform
# Get Flink region data
data "confluent_flink_region" "main" {
  cloud  = "AWS"
  region = "us-west-2"
}

# Create Flink API key owned by the service account
resource "confluent_api_key" "flink_api_key" {
  display_name = "flink-api-key-terraform"
  description  = "Flink API Key for Terraform deployments"
  
  owner {
    id          = var.flink_principal_id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }

  managed_resource {
    id          = data.confluent_flink_region.main.id
    api_version = "fcpm/v2"
    kind        = "Region"
    
    environment {
      id = var.environment_id
    }
  }
}

# Then use it in the Flink statement:
resource "confluent_flink_statement" "create-function" {
  # ... other configuration ...
  credentials {
    key    = confluent_api_key.flink_api_key.id
    secret = confluent_api_key.flink_api_key.secret
  }
}
```
