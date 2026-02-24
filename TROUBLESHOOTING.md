# Troubleshooting Guide - Cross-Account Setup

This guide covers common issues and their solutions when setting up cross-account S3 access with Amplify and Microsoft Entra ID.

## Table of Contents

1. [Authentication Issues](#authentication-issues)
2. [Cross-Account Access Issues](#cross-account-access-issues)
3. [Landing Zone Issues](#landing-zone-issues)
4. [Deployment Issues](#deployment-issues)
5. [Network Issues](#network-issues)
6. [Debugging Tools](#debugging-tools)

---

## Authentication Issues

### Issue: SAML Authentication Fails

**Symptoms:**
- Redirect loop after Entra ID login
- "Invalid SAML response" error
- User redirected back to login page

**Solutions:**

1. **Verify SAML Configuration in Entra ID**
   ```bash
   # Check Cognito SAML provider configuration
   aws cognito-idp describe-identity-provider \
     --user-pool-id YOUR_POOL_ID \
     --provider-name EntraID
   ```

2. **Check Entity ID and Reply URL**
   - Entity ID should be: `urn:amazon:cognito:sp:<USER_POOL_ID>`
   - Reply URL should be: `https://<DOMAIN>.auth.<REGION>.amazoncognito.com/saml2/idpresponse`

3. **Verify Attributes Mapping**
   - Email claim: `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress`
   - Name claim: `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name`

4. **Check Federation Metadata**
   ```bash
   # Download and verify metadata
   curl -o metadata.xml "https://login.microsoftonline.com/TENANT_ID/federationmetadata/2007-06/federationmetadata.xml"
   ```

### Issue: User Not Assigned to Application

**Symptoms:**
- "AADSTS50105: The signed in user is not assigned to a role for the application"

**Solution:**
1. Go to Entra Admin Center
2. Navigate to Enterprise Applications > Your App
3. Click "Users and groups"
4. Add users or groups to the application

### Issue: Token Expiration

**Symptoms:**
- User logged out unexpectedly
- "Token expired" error

**Solution:**
1. Adjust token lifetime in Cognito:
   ```bash
   aws cognito-idp update-user-pool \
     --user-pool-id YOUR_POOL_ID \
     --user-pool-add-ons AdvancedSecurityMode=ENFORCED \
     --policies "PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true}"
   ```

2. Implement token refresh in your app:
   ```typescript
   import { fetchAuthSession } from 'aws-amplify/auth';
   
   // Refresh session before making API calls
   const session = await fetchAuthSession({ forceRefresh: true });
   ```

---

## Cross-Account Access Issues

### Issue: "Access Denied" When Assuming Role

**Symptoms:**
- `AccessDenied` error when calling `sts:AssumeRole`
- "User is not authorized to perform: sts:AssumeRole"

**Solutions:**

1. **Verify Trust Policy in Target Account**
   ```bash
   aws iam get-role \
     --role-name AmplifyStorageCrossAccountRole \
     --query 'Role.AssumeRolePolicyDocument'
   ```

   Should include:
   ```json
   {
     "Effect": "Allow",
     "Principal": {
       "Federated": "cognito-identity.amazonaws.com"
     },
     "Condition": {
       "StringEquals": {
         "cognito-identity.amazonaws.com:aud": "YOUR_IDENTITY_POOL_ID"
       }
     }
   }
   ```

2. **Verify Authenticated Role Has AssumeRole Permission**
   ```bash
   # Get authenticated role ARN
   aws cognito-identity get-identity-pool-roles \
     --identity-pool-id YOUR_IDENTITY_POOL_ID
   
   # Check role policies
   aws iam list-role-policies --role-name YOUR_AUTH_ROLE
   aws iam get-role-policy --role-name YOUR_AUTH_ROLE --policy-name POLICY_NAME
   ```

3. **Check Identity Pool ID Match**
   - Ensure the Identity Pool ID in trust policy matches your actual pool
   - Verify you're using the correct region

### Issue: "Access Denied" When Accessing S3

**Symptoms:**
- Can assume role but can't list/read/write S3 objects
- `AccessDenied` on S3 operations

**Solutions:**

1. **Verify S3 Permissions on Cross-Account Role**
   ```bash
   aws iam get-role-policy \
     --role-name AmplifyStorageCrossAccountRole \
     --policy-name S3BucketAccess
   ```

2. **Check Bucket Policy**
   ```bash
   aws s3api get-bucket-policy \
     --bucket your-bucket-name \
     --query Policy \
     --output text | jq .
   ```

3. **Verify Bucket Encryption Settings**
   - If bucket uses KMS encryption, add KMS permissions:
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "kms:Decrypt",
       "kms:GenerateDataKey"
     ],
     "Resource": "arn:aws:kms:REGION:ACCOUNT:key/KEY_ID"
   }
   ```

4. **Check for Explicit Denies**
   - Look for deny statements in bucket policies
   - Check for SCPs that might block access

### Issue: Can't Access User-Specific Paths

**Symptoms:**
- Can access public paths but not `private/{entity_id}/*`
- "Access Denied" on user-specific folders

**Solutions:**

1. **Verify Policy Variable Substitution**
   ```json
   {
     "Resource": "arn:aws:s3:::bucket/private/${cognito-identity.amazonaws.com:sub}/*"
   }
   ```

2. **Check Identity ID Format**
   ```typescript
   import { fetchAuthSession } from 'aws-amplify/auth';
   
   const session = await fetchAuthSession();
   console.log('Identity ID:', session.identityId);
   // Should be: us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

---

## Landing Zone Issues

### Issue: Service Control Policy (SCP) Blocks Access

**Symptoms:**
- Operations fail with "Access Denied" even with correct IAM policies
- Error mentions "organizational policy"

**Solutions:**

1. **Check SCPs in Organization**
   ```bash
   # List SCPs attached to account
   aws organizations list-policies-for-target \
     --target-id ACCOUNT_ID \
     --filter SERVICE_CONTROL_POLICY
   ```

2. **Review SCP Content**
   ```bash
   aws organizations describe-policy \
     --policy-id POLICY_ID
   ```

3. **Required SCP Permissions**
   Ensure SCPs allow:
   - `sts:AssumeRole`
   - `sts:AssumeRoleWithWebIdentity`
   - `cognito-identity:GetCredentialsForIdentity`
   - `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`

4. **Request SCP Exception**
   - Contact your cloud platform team
   - Provide business justification
   - Reference: `iam-policies/landing-zone-scp-requirements.json`

### Issue: VPC Endpoint Required

**Symptoms:**
- Timeouts when accessing S3
- "Could not connect to the endpoint URL"

**Solutions:**

1. **Create VPC Endpoint for S3**
   ```bash
   aws ec2 create-vpc-endpoint \
     --vpc-id vpc-xxxxx \
     --service-name com.amazonaws.REGION.s3 \
     --route-table-ids rtb-xxxxx
   ```

2. **Create VPC Endpoint for STS**
   ```bash
   aws ec2 create-vpc-endpoint \
     --vpc-id vpc-xxxxx \
     --service-name com.amazonaws.REGION.sts \
     --vpc-endpoint-type Interface \
     --subnet-ids subnet-xxxxx
   ```

### Issue: Control Tower Guardrails Block Deployment

**Symptoms:**
- Can't create IAM roles
- "Guardrail violation" errors

**Solutions:**

1. **Check Guardrail Status**
   - Review Control Tower dashboard
   - Identify which guardrail is blocking

2. **Request Guardrail Exception**
   - Work with cloud platform team
   - Document security controls you're implementing

3. **Use Approved Patterns**
   - Follow organization's approved reference architectures
   - Use pre-approved IAM role templates

---

## Deployment Issues

### Issue: Amplify Deployment Fails

**Symptoms:**
- `npx ampx sandbox` fails
- CDK deployment errors

**Solutions:**

1. **Check AWS Credentials**
   ```bash
   aws sts get-caller-identity
   ```

2. **Verify Required Permissions**
   - CloudFormation
   - IAM
   - Cognito
   - S3
   - Lambda

3. **Clear CDK Cache**
   ```bash
   rm -rf .amplify
   rm -rf node_modules/.cache
   npx ampx sandbox --clean
   ```

4. **Check CDK Bootstrap**
   ```bash
   npx cdk bootstrap aws://ACCOUNT_ID/REGION
   ```

### Issue: Script Execution Fails

**Symptoms:**
- `./scripts/deploy-cross-account-roles.sh` fails
- Permission denied errors

**Solutions:**

1. **Make Script Executable**
   ```bash
   chmod +x scripts/deploy-cross-account-roles.sh
   chmod +x scripts/validate-setup.sh
   ```

2. **Check Shell**
   ```bash
   # Ensure using bash
   bash scripts/deploy-cross-account-roles.sh
   ```

3. **Verify jq Installation**
   ```bash
   # macOS
   brew install jq
   
   # Linux
   sudo apt-get install jq
   ```

---

## Network Issues

### Issue: CORS Errors

**Symptoms:**
- "CORS policy" errors in browser console
- Can't upload/download files

**Solutions:**

1. **Configure S3 CORS**
   ```bash
   aws s3api put-bucket-cors \
     --bucket your-bucket-name \
     --cors-configuration file://cors.json
   ```

   `cors.json`:
   ```json
   {
     "CORSRules": [{
       "AllowedOrigins": ["http://localhost:5173", "https://yourdomain.com"],
       "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
       "AllowedHeaders": ["*"],
       "ExposeHeaders": ["ETag"],
       "MaxAgeSeconds": 3000
     }]
   }
   ```

### Issue: Timeout Errors

**Symptoms:**
- Operations timeout
- "Request timed out" errors

**Solutions:**

1. **Increase Timeout**
   ```typescript
   const s3Client = new S3Client({
     region,
     credentials,
     requestHandler: {
       requestTimeout: 30000, // 30 seconds
     },
   });
   ```

2. **Check Network Connectivity**
   ```bash
   # Test S3 endpoint
   curl -I https://s3.REGION.amazonaws.com
   
   # Test STS endpoint
   curl -I https://sts.REGION.amazonaws.com
   ```

---

## Debugging Tools

### Enable Verbose Logging

```typescript
// In your app
import { Amplify } from 'aws-amplify';

Amplify.configure({
  ...config,
  Auth: {
    ...config.Auth,
    oauth: {
      ...config.Auth.oauth,
      // Enable debug logging
      debug: true,
    },
  },
});
```

### Check CloudTrail Logs

```bash
# Find AssumeRole events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --max-results 10

# Find S3 access events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::S3::Bucket \
  --max-results 10
```

### Test IAM Policies

```bash
# Simulate IAM policy
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:role/ROLE_NAME \
  --action-names s3:GetObject s3:PutObject \
  --resource-arns arn:aws:s3:::bucket-name/*
```

### Validate JSON Policies

```bash
# Validate JSON syntax
cat iam-policies/account-b-trust-policy.json | jq .

# Check for common issues
cat iam-policies/account-b-trust-policy.json | jq '.Statement[].Principal'
```

### Browser Console Debugging

```javascript
// In browser console
import { fetchAuthSession } from 'aws-amplify/auth';

// Check current session
const session = await fetchAuthSession();
console.log('Session:', session);
console.log('Identity ID:', session.identityId);
console.log('Credentials:', session.credentials);

// Test cross-account access
import { runAllTests } from './src/test/cross-account-test';
await runAllTests();
```

---

## Getting Help

If you're still experiencing issues:

1. **Check AWS Service Health**
   - https://status.aws.amazon.com/

2. **Review AWS Documentation**
   - [Amplify Documentation](https://docs.amplify.aws/)
   - [Cognito Documentation](https://docs.aws.amazon.com/cognito/)
   - [S3 Cross-Account Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-walkthroughs-managing-access.html)

3. **Contact Support**
   - AWS Support (if you have a support plan)
   - Your organization's cloud platform team
   - [AWS re:Post](https://repost.aws/)

4. **Community Resources**
   - [AWS Amplify Discord](https://discord.gg/amplify)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/aws-amplify)
   - [GitHub Issues](https://github.com/aws-amplify/amplify-js/issues)

---

## Preventive Measures

To avoid common issues:

1. **Run Validation Before Deployment**
   ```bash
   ./scripts/validate-setup.sh
   ```

2. **Use Configuration Template**
   - Copy `config-template.env` to `.env`
   - Fill in all values before deployment

3. **Test in Stages**
   - Test authentication first
   - Then test same-account S3 access
   - Finally test cross-account access

4. **Enable Logging**
   - CloudTrail in all accounts
   - S3 access logging
   - Cognito advanced security features

5. **Document Your Setup**
   - Keep track of account IDs
   - Document custom configurations
   - Maintain runbooks for common operations
