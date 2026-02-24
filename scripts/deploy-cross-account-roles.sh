#!/bin/bash

# Deploy Cross-Account IAM Roles for Amplify Storage Browser
# This script creates IAM roles in Account B and Account C that can be assumed by Cognito Identity Pool

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cross-Account IAM Role Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if required tools are installed
command -v aws >/dev/null 2>&1 || { echo -e "${RED}Error: AWS CLI is not installed${NC}" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}Error: jq is not installed${NC}" >&2; exit 1; }

# Configuration
IDENTITY_POOL_ID=""
ACCOUNT_B_ID=""
ACCOUNT_C_ID=""
ACCOUNT_B_BUCKET=""
ACCOUNT_C_BUCKET=""
REGION="ap-southeast-1"

# Prompt for configuration
echo -e "${YELLOW}Please provide the following information:${NC}"
echo ""

read -p "Cognito Identity Pool ID (e.g., us-east-1:xxxx-xxxx): " IDENTITY_POOL_ID
read -p "Account B ID (e.g., 222222222222): " ACCOUNT_B_ID
read -p "Account B Bucket Name: " ACCOUNT_B_BUCKET
read -p "Account C ID (e.g., 333333333333): " ACCOUNT_C_ID
read -p "Account C Bucket Name: " ACCOUNT_C_BUCKET
read -p "AWS Region [ap-southeast-1]: " REGION_INPUT
REGION=${REGION_INPUT:-$REGION}

echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "Identity Pool ID: $IDENTITY_POOL_ID"
echo "Account B ID: $ACCOUNT_B_ID"
echo "Account B Bucket: $ACCOUNT_B_BUCKET"
echo "Account C ID: $ACCOUNT_C_ID"
echo "Account C Bucket: $ACCOUNT_C_BUCKET"
echo "Region: $REGION"
echo ""

read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# Function to deploy role in an account
deploy_role() {
    local ACCOUNT_ID=$1
    local BUCKET_NAME=$2
    local ACCOUNT_LABEL=$3
    
    echo ""
    echo -e "${GREEN}Deploying role in Account $ACCOUNT_LABEL ($ACCOUNT_ID)...${NC}"
    
    # Update trust policy
    cat iam-policies/account-b-trust-policy.json | \
        sed "s/REPLACE_WITH_YOUR_IDENTITY_POOL_ID/$IDENTITY_POOL_ID/g" > /tmp/trust-policy-$ACCOUNT_ID.json
    
    # Update S3 permissions
    cat iam-policies/account-b-s3-permissions.json | \
        sed "s/REPLACE_WITH_BUCKET_NAME/$BUCKET_NAME/g" > /tmp/s3-permissions-$ACCOUNT_ID.json
    
    # Update bucket policy
    cat iam-policies/account-b-bucket-policy.json | \
        sed "s/REPLACE_WITH_ACCOUNT_B_ID/$ACCOUNT_ID/g" | \
        sed "s/REPLACE_WITH_BUCKET_NAME/$BUCKET_NAME/g" > /tmp/bucket-policy-$ACCOUNT_ID.json
    
    # Create or update IAM role
    echo "Creating IAM role..."
    aws iam create-role \
        --role-name AmplifyStorageCrossAccountRole \
        --assume-role-policy-document file:///tmp/trust-policy-$ACCOUNT_ID.json \
        --region $REGION \
        2>/dev/null || \
    aws iam update-assume-role-policy \
        --role-name AmplifyStorageCrossAccountRole \
        --policy-document file:///tmp/trust-policy-$ACCOUNT_ID.json \
        --region $REGION
    
    # Attach inline policy
    echo "Attaching S3 permissions..."
    aws iam put-role-policy \
        --role-name AmplifyStorageCrossAccountRole \
        --policy-name S3BucketAccess \
        --policy-document file:///tmp/s3-permissions-$ACCOUNT_ID.json \
        --region $REGION
    
    # Apply bucket policy
    echo "Applying bucket policy..."
    aws s3api put-bucket-policy \
        --bucket $BUCKET_NAME \
        --policy file:///tmp/bucket-policy-$ACCOUNT_ID.json \
        --region $REGION
    
    echo -e "${GREEN}✅ Role deployed successfully in Account $ACCOUNT_LABEL${NC}"
    
    # Cleanup temp files
    rm /tmp/trust-policy-$ACCOUNT_ID.json
    rm /tmp/s3-permissions-$ACCOUNT_ID.json
    rm /tmp/bucket-policy-$ACCOUNT_ID.json
}

# Deploy to Account B
echo ""
echo -e "${YELLOW}Switch to Account B AWS profile and press Enter...${NC}"
read
deploy_role $ACCOUNT_B_ID $ACCOUNT_B_BUCKET "B"

# Deploy to Account C
echo ""
echo -e "${YELLOW}Switch to Account C AWS profile and press Enter...${NC}"
read
deploy_role $ACCOUNT_C_ID $ACCOUNT_C_BUCKET "C"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update amplify/backend/custom-resources.ts with your account IDs"
echo "2. Update src/config/cross-account-storage.ts with your bucket names and role ARNs"
echo "3. Uncomment addCrossAccountAccess(backend) in amplify/backend.ts"
echo "4. Run: npx ampx sandbox"
echo ""
echo -e "${GREEN}Role ARNs:${NC}"
echo "Account B: arn:aws:iam::$ACCOUNT_B_ID:role/AmplifyStorageCrossAccountRole"
echo "Account C: arn:aws:iam::$ACCOUNT_C_ID:role/AmplifyStorageCrossAccountRole"
