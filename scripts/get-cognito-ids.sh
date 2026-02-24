#!/bin/bash

# Get Cognito Pool IDs after Amplify deployment
# Run this after: npx ampx sandbox

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Getting Cognito Pool IDs${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get AWS region (default to ap-southeast-1)
REGION=${AWS_REGION:-ap-southeast-1}
echo -e "${YELLOW}Using region: $REGION${NC}"
echo ""

# Get User Pool ID
echo -e "${BLUE}Cognito User Pool:${NC}"
USER_POOL_ID=$(aws cognito-idp list-user-pools --max-results 10 --region $REGION \
  --query "UserPools[?contains(Name, 'amplify') || contains(Name, 'Amplify')].Id" \
  --output text | head -n 1)

if [ -n "$USER_POOL_ID" ]; then
  echo -e "${GREEN}✓ User Pool ID: $USER_POOL_ID${NC}"
  
  # Get User Pool details
  USER_POOL_DOMAIN=$(aws cognito-idp describe-user-pool \
    --user-pool-id $USER_POOL_ID \
    --region $REGION \
    --query "UserPool.Domain" \
    --output text 2>/dev/null || echo "")
  
  if [ -n "$USER_POOL_DOMAIN" ] && [ "$USER_POOL_DOMAIN" != "None" ]; then
    echo -e "${GREEN}✓ User Pool Domain: https://$USER_POOL_DOMAIN.auth.$REGION.amazoncognito.com${NC}"
  else
    echo -e "${YELLOW}⚠ No custom domain configured${NC}"
  fi
else
  echo -e "${YELLOW}⚠ No User Pool found. Have you deployed Amplify?${NC}"
fi

echo ""

# Get Identity Pool ID
echo -e "${BLUE}Cognito Identity Pool:${NC}"
IDENTITY_POOL_ID=$(aws cognito-identity list-identity-pools --max-results 10 --region $REGION \
  --query "IdentityPools[?contains(IdentityPoolName, 'amplify') || contains(IdentityPoolName, 'Amplify')].IdentityPoolId" \
  --output text | head -n 1)

if [ -n "$IDENTITY_POOL_ID" ]; then
  echo -e "${GREEN}✓ Identity Pool ID: $IDENTITY_POOL_ID${NC}"
else
  echo -e "${YELLOW}⚠ No Identity Pool found. Have you deployed Amplify?${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ -n "$USER_POOL_ID" ] && [ -n "$IDENTITY_POOL_ID" ]; then
  echo -e "${GREEN}✓ All Cognito resources found!${NC}"
  echo ""
  echo "Copy these values:"
  echo ""
  echo "User Pool ID:"
  echo "  $USER_POOL_ID"
  echo ""
  echo "Identity Pool ID:"
  echo "  $IDENTITY_POOL_ID"
  echo ""
  echo "Entra ID Configuration:"
  echo "  Entity ID: urn:amazon:cognito:sp:$USER_POOL_ID"
  if [ -n "$USER_POOL_DOMAIN" ] && [ "$USER_POOL_DOMAIN" != "None" ]; then
    echo "  Reply URL: https://$USER_POOL_DOMAIN.auth.$REGION.amazoncognito.com/saml2/idpresponse"
  fi
  echo ""
  echo -e "${YELLOW}Next steps:${NC}"
  echo "1. Update Entra ID SAML configuration with Entity ID and Reply URL"
  echo "2. Update iam-policies/*.json files with Identity Pool ID: $IDENTITY_POOL_ID"
  echo "3. Run: ./scripts/deploy-cross-account-roles.sh"
else
  echo -e "${YELLOW}⚠ Cognito resources not found${NC}"
  echo ""
  echo "Please run: npx ampx sandbox"
  echo "Then run this script again"
fi

echo ""
