#!/bin/bash

# Script to verify Flink API credentials and service account permissions
# This helps diagnose 401 Unauthorized errors

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Verifying Flink API credentials and permissions...${NC}\n"

# Check if Confluent CLI is installed
if ! command -v confluent &> /dev/null; then
    echo -e "${RED}Error: Confluent CLI is not installed${NC}"
    exit 1
fi

# Check if user is logged in
if ! confluent environment list &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Confluent Cloud${NC}"
    echo "Please run: confluent login"
    exit 1
fi

# Read variables from terraform.tfvars (simple parsing)
if [[ ! -f "terraform.tfvars" ]]; then
    echo -e "${RED}Error: terraform.tfvars not found${NC}"
    exit 1
fi

# Extract values (simple grep-based extraction)
FLINK_API_KEY=$(grep -E '^flink_api_key\s*=' terraform.tfvars | sed 's/.*=\s*"\(.*\)"/\1/' | tr -d ' ')
FLINK_PRINCIPAL_ID=$(grep -E '^flink_principal_id\s*=' terraform.tfvars | sed 's/.*=\s*"\(.*\)"/\1/' | tr -d ' ')
COMPUTE_POOL_ID=$(grep -E '^flink_compute_pool_id\s*=' terraform.tfvars | sed 's/.*=\s*"\(.*\)"/\1/' | tr -d ' ')

if [[ -z "$FLINK_API_KEY" ]] || [[ -z "$FLINK_PRINCIPAL_ID" ]] || [[ -z "$COMPUTE_POOL_ID" ]]; then
    echo -e "${RED}Error: Could not extract required variables from terraform.tfvars${NC}"
    exit 1
fi

echo "Flink API Key: ${FLINK_API_KEY:0:10}..."
echo "Principal ID: $FLINK_PRINCIPAL_ID"
echo "Compute Pool ID: $COMPUTE_POOL_ID"
echo ""

# Check API key details
echo -e "${YELLOW}1. Checking Flink API Key details...${NC}"
API_KEY_INFO=$(confluent api-key describe "$FLINK_API_KEY" --output json 2>&1 || echo "ERROR")

if echo "$API_KEY_INFO" | grep -q "ERROR"; then
    echo -e "${RED}✗ Failed to retrieve API key information${NC}"
    echo "  The API key might be invalid or you don't have permission to view it"
else
    OWNER=$(echo "$API_KEY_INFO" | grep -o '"owner":"[^"]*' | cut -d'"' -f4 || echo "unknown")
    RESOURCE=$(echo "$API_KEY_INFO" | grep -o '"resource":"[^"]*' | cut -d'"' -f4 || echo "unknown")
    
    echo -e "${GREEN}✓ API Key exists${NC}"
    echo "  Owner: $OWNER"
    echo "  Resource: $RESOURCE"
    
    if [[ "$OWNER" != *"$FLINK_PRINCIPAL_ID"* ]]; then
        echo -e "${RED}  ⚠ WARNING: API key owner does not match principal ID!${NC}"
        echo "    Expected: $FLINK_PRINCIPAL_ID"
        echo "    Found: $OWNER"
    else
        echo -e "${GREEN}  ✓ API key is owned by the correct principal${NC}"
    fi
fi

echo ""

# Check service account role bindings
echo -e "${YELLOW}2. Checking service account role bindings...${NC}"
ROLE_BINDINGS=$(confluent iam rbac role-binding list --principal "User:$FLINK_PRINCIPAL_ID" --output json 2>&1 || echo "ERROR")

if echo "$ROLE_BINDINGS" | grep -q "ERROR"; then
    echo -e "${RED}✗ Failed to retrieve role bindings${NC}"
    echo "  You might not have permission to view role bindings"
else
    FLINK_ADMIN_COUNT=$(echo "$ROLE_BINDINGS" | grep -i "FlinkAdmin" | wc -l | tr -d ' ')
    
    if [[ "$FLINK_ADMIN_COUNT" -gt 0 ]]; then
        echo -e "${GREEN}✓ Service account has FlinkAdmin role${NC}"
        echo "$ROLE_BINDINGS" | grep -i "FlinkAdmin" | head -3
    else
        echo -e "${RED}✗ Service account does NOT have FlinkAdmin role${NC}"
        echo "  The service account needs FlinkAdmin role on the compute pool"
    fi
fi

echo ""

# Summary
echo -e "${YELLOW}Summary:${NC}"
echo "If you see warnings above, those are likely the cause of the 401 error."
echo ""
echo "To fix:"
echo "1. Ensure the Flink API key is owned by service account: $FLINK_PRINCIPAL_ID"
echo "2. Ensure the service account has FlinkAdmin role on compute pool: $COMPUTE_POOL_ID"
echo "3. Verify the API key is scoped to the Flink region (not just Kafka cluster)"
