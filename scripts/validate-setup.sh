#!/bin/bash

# Validate Cross-Account Setup
# This script checks if all required resources are properly configured

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Cross-Account Setup Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if a command exists
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check AWS CLI configuration
check_aws_profile() {
    local PROFILE=$1
    if aws sts get-caller-identity --profile $PROFILE &> /dev/null; then
        echo -e "${GREEN}✓${NC} AWS profile '$PROFILE' is configured"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} AWS profile '$PROFILE' is not configured or invalid"
        WARNINGS=$((WARNINGS + 1))
        return 1
    fi
}

# Check required tools
echo -e "${BLUE}Checking required tools...${NC}"
check_command "node"
check_command "npm"
check_command "aws"
check_command "jq"
echo ""

# Check Node.js version
echo -e "${BLUE}Checking Node.js version...${NC}"
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -ge 18 ]; then
    echo -e "${GREEN}✓${NC} Node.js version is $NODE_VERSION (>= 18 required)"
else
    echo -e "${RED}✗${NC} Node.js version is $NODE_VERSION (>= 18 required)"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check if package.json exists
echo -e "${BLUE}Checking project files...${NC}"
if [ -f "package.json" ]; then
    echo -e "${GREEN}✓${NC} package.json exists"
else
    echo -e "${RED}✗${NC} package.json not found"
    ERRORS=$((ERRORS + 1))
fi

# Check if required directories exist
for dir in "amplify" "src" "iam-policies" "scripts"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} Directory '$dir' exists"
    else
        echo -e "${RED}✗${NC} Directory '$dir' not found"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check if required configuration files exist
echo -e "${BLUE}Checking configuration files...${NC}"
CONFIG_FILES=(
    "amplify/auth/resource.ts"
    "amplify/storage/resource.ts"
    "amplify/backend.ts"
    "amplify/backend/custom-resources.ts"
    "src/config/cross-account-storage.ts"
    "src/utils/cross-account-storage.ts"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file exists"
    else
        echo -e "${RED}✗${NC} $file not found"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check if IAM policy templates exist
echo -e "${BLUE}Checking IAM policy templates...${NC}"
POLICY_FILES=(
    "iam-policies/account-b-trust-policy.json"
    "iam-policies/account-b-s3-permissions.json"
    "iam-policies/account-b-bucket-policy.json"
    "iam-policies/account-c-trust-policy.json"
    "iam-policies/account-c-s3-permissions.json"
    "iam-policies/account-c-bucket-policy.json"
)

for file in "${POLICY_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file exists"
    else
        echo -e "${RED}✗${NC} $file not found"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check if dependencies are installed
echo -e "${BLUE}Checking npm dependencies...${NC}"
if [ -d "node_modules" ]; then
    echo -e "${GREEN}✓${NC} node_modules directory exists"
    
    # Check for specific required packages
    REQUIRED_PACKAGES=("aws-amplify" "@aws-sdk/client-s3" "@aws-sdk/client-sts")
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if [ -d "node_modules/$pkg" ]; then
            echo -e "${GREEN}✓${NC} Package '$pkg' is installed"
        else
            echo -e "${YELLOW}⚠${NC} Package '$pkg' is not installed"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
else
    echo -e "${YELLOW}⚠${NC} node_modules not found. Run 'npm install'"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check for placeholder values in configuration
echo -e "${BLUE}Checking for placeholder values...${NC}"
if grep -r "REPLACE_WITH" iam-policies/ &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Found placeholder values in IAM policies"
    echo "   Run the deployment script to replace these values"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} No placeholder values found in IAM policies"
fi

if grep -q "222222222222\|333333333333" amplify/backend/custom-resources.ts 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Found example account IDs in custom-resources.ts"
    echo "   Update with your actual account IDs"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} custom-resources.ts appears to be configured"
fi

if grep -q "your-bucket-name" src/config/cross-account-storage.ts 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Found placeholder bucket names in cross-account-storage.ts"
    echo "   Update with your actual bucket names"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} cross-account-storage.ts appears to be configured"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run: npm install (if not done)"
    echo "2. Run: npx ampx sandbox"
    echo "3. Configure Entra ID SAML"
    echo "4. Run: ./scripts/deploy-cross-account-roles.sh"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation completed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "Review the warnings above and update configuration as needed."
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before proceeding."
    exit 1
fi
