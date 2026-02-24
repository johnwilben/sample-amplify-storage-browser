# Cross-Account S3 Access with Amplify Storage Browser and Microsoft Entra ID

This guide explains how to set up AWS Amplify Storage Browser with Microsoft Entra ID (Azure AD) authentication to access S3 buckets across multiple AWS accounts in a landing zone environment.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Microsoft Entra ID (Azure)                  │
│                    (Enterprise Identity Provider)               │
└────────────────────────────┬────────────────────────────────────┘
                             │ SAML Authentication
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Account A (Amplify Account)                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Amplify App + Cognito User Pool + Identity Pool         │  │
│  │  - Entra ID SAML Federation                              │  │
│  │  - Authenticated Role (can assume cross-account roles)   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │ AssumeRole
                ┌────────────┴────────────┐
                ▼                         ▼
┌───────────────────────────┐  ┌───────────────────────────┐
│  Account B (Bucket Acct)  │  │  Account C (Bucket Acct)  │
│  ┌─────────────────────┐  │  │  ┌─────────────────────┐  │
│  │ S3 Bucket           │  │  │  │ S3 Bucket           │  │
│  │ IAM Cross-Acct Role │  │  │  │ IAM Cross-Acct Role │  │
│  └─────────────────────┘  │  │  └─────────────────────┘  │
└───────────────────────────┘  └───────────────────────────┘
```

## Prerequisites

- AWS Landing Zone or Control Tower setup
- Microsoft Entra ID tenant with admin access
- Multiple AWS accounts (one for Amplify, others for S3 buckets)
- Permissions to create IAM roles and policies across accounts
- Node.js 18+ and npm installed

## Account Structure

- **Account A (Amplify Account)**: `111111111111` - Hosts Amplify app, Cognito
- **Account B (Storage Account 1)**: `222222222222` - Hosts S3 buckets
- **Account C (Storage Account 2)**: `333333333333` - Hosts S3 buckets

Replace these account IDs with your actual AWS account numbers.

## Step 1: Configure Microsoft Entra ID SAML

### 1.1 Create Enterprise Application in Entra ID

1. Sign in to [Microsoft Entra Admin Center](https://entra.microsoft.com)
2. Navigate to **Identity** > **Applications** > **Enterprise applications**
3. Click **New application** > **Create your own application**
4. Name it "Amplify Storage Browser" and select **Integrate any other application**
5. Click **Create**

### 1.2 Configure SAML Single Sign-On

1. In your new application, go to **Single sign-on** > **SAML**
2. Click **Edit** on Basic SAML Configuration
3. You'll configure these values after deploying Amplify (Step 2)

Keep this browser tab open - you'll return here after deploying Amplify.

## Step 2: Deploy Amplify with Entra ID Authentication

### 2.1 Update Auth Configuration

Update `amplify/auth/resource.ts`:

```typescript
import { defineAuth } from '@aws-amplify/backend';

export const auth = defineAuth({
  loginWith: {
    email: true,
    externalProviders: {
      saml: {
        name: 'EntraID',
        metadata: {
          metadataType: 'url',
          // You'll get this URL from Entra ID in Step 1.2
          metadataContent: 'https://login.microsoftonline.com/<TENANT_ID>/federationmetadata/2007-06/federationmetadata.xml'
        }
      }
    }
  },
  groups: ['admin', 'users']
});
```

### 2.2 Deploy Amplify Backend

```bash
npm install
npx ampx sandbox
```

After deployment, note these values from the output:
- **Cognito User Pool ID**: `us-east-1_XXXXXXXXX`
- **Cognito Identity Pool ID**: `us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **User Pool Domain**: `https://xxxxx.auth.us-east-1.amazoncognito.com`

### 2.3 Complete Entra ID SAML Configuration

Return to Entra ID Admin Center:

1. **Basic SAML Configuration**:
   - Identifier (Entity ID): `urn:amazon:cognito:sp:<USER_POOL_ID>`
   - Reply URL: `https://<USER_POOL_DOMAIN>/saml2/idpresponse`

2. **Attributes & Claims**:
   - Add claim: `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress` → `user.mail`
   - Add claim: `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name` → `user.userprincipalname`

3. **Download** the Federation Metadata XML and note the metadata URL

4. **Assign users** to the application under **Users and groups**

## Step 3: Set Up Cross-Account IAM Roles

### 3.1 Get Cognito Identity Pool ID

After Amplify deployment, get your Identity Pool ID:

```bash
aws cognito-identity list-identity-pools --max-results 10 --region us-east-1
```

### 3.2 Create IAM Role in Account B (Storage Account)

Create file: `iam-policies/account-b-cross-account-role.json`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "us-east-1:YOUR-IDENTITY-POOL-ID"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
```

Deploy in Account B:

```bash
# Switch to Account B
export AWS_PROFILE=account-b

# Create the role
aws iam create-role \
  --role-name AmplifyStorageCrossAccountRole \
  --assume-role-policy-document file://iam-policies/account-b-cross-account-role.json

# Attach S3 access policy
aws iam put-role-policy \
  --role-name AmplifyStorageCrossAccountRole \
  --policy-name S3BucketAccess \
  --policy-document file://iam-policies/account-b-s3-policy.json
```

### 3.3 Create S3 Bucket Policy in Account B

Create file: `iam-policies/account-b-s3-policy.json`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket-name-account-b/*",
        "arn:aws:s3:::your-bucket-name-account-b"
      ]
    }
  ]
}
```

Apply bucket policy:

```bash
aws s3api put-bucket-policy \
  --bucket your-bucket-name-account-b \
  --policy file://iam-policies/account-b-bucket-policy.json
```

### 3.4 Repeat for Account C

Repeat steps 3.2 and 3.3 for Account C with appropriate bucket names.

## Step 4: Update Amplify Backend for Cross-Account Access

### 4.1 Create Custom Backend Configuration

Create file: `amplify/backend/custom-resources.ts`

```typescript
import { defineBackend } from '@aws-amplify/backend';
import { PolicyStatement, Effect } from 'aws-cdk-lib/aws-iam';

export function addCrossAccountAccess(backend: any) {
  const authenticatedRole = backend.auth.resources.authenticatedUserIamRole;
  
  // Allow assuming roles in other accounts
  authenticatedRole.addToPrincipalPolicy(
    new PolicyStatement({
      effect: Effect.ALLOW,
      actions: ['sts:AssumeRole'],
      resources: [
        'arn:aws:iam::222222222222:role/AmplifyStorageCrossAccountRole', // Account B
        'arn:aws:iam::333333333333:role/AmplifyStorageCrossAccountRole', // Account C
      ],
    })
  );
}
```

### 4.2 Update Backend Configuration

Update `amplify/backend.ts`:

```typescript
import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { storage, secondaryStorage } from './storage/resource';
import { addCrossAccountAccess } from './backend/custom-resources';

const backend = defineBackend({
  auth,
  storage,
  secondaryStorage
});

// Add cross-account access permissions
addCrossAccountAccess(backend);
```

### 4.3 Redeploy

```bash
npx ampx sandbox
```

## Step 5: Configure Frontend for Cross-Account Access

### 5.1 Create Cross-Account Storage Configuration

Create file: `src/config/cross-account-storage.ts`

```typescript
export const crossAccountBuckets = {
  accountB: {
    bucket: 'your-bucket-name-account-b',
    region: 'us-east-1',
    roleArn: 'arn:aws:iam::222222222222:role/AmplifyStorageCrossAccountRole',
  },
  accountC: {
    bucket: 'your-bucket-name-account-c',
    region: 'us-east-1',
    roleArn: 'arn:aws:iam::333333333333:role/AmplifyStorageCrossAccountRole',
  },
};
```

### 5.2 Create Cross-Account Storage Helper

Create file: `src/utils/cross-account-storage.ts`

```typescript
import { fetchAuthSession } from 'aws-amplify/auth';
import { STS } from '@aws-sdk/client-sts';
import { S3Client } from '@aws-sdk/client-s3';

export async function getCrossAccountS3Client(roleArn: string, region: string) {
  // Get current Cognito credentials
  const session = await fetchAuthSession();
  
  if (!session.credentials) {
    throw new Error('No credentials available');
  }

  // Create STS client with Cognito credentials
  const sts = new STS({
    region,
    credentials: session.credentials,
  });

  // Assume the cross-account role
  const assumedRole = await sts.assumeRole({
    RoleArn: roleArn,
    RoleSessionName: 'amplify-storage-session',
    DurationSeconds: 3600,
  });

  if (!assumedRole.Credentials) {
    throw new Error('Failed to assume role');
  }

  // Create S3 client with assumed role credentials
  return new S3Client({
    region,
    credentials: {
      accessKeyId: assumedRole.Credentials.AccessKeyId!,
      secretAccessKey: assumedRole.Credentials.SecretAccessKey!,
      sessionToken: assumedRole.Credentials.SessionToken!,
    },
  });
}
```

### 5.3 Install Required Dependencies

```bash
npm install @aws-sdk/client-sts @aws-sdk/client-s3
```

## Step 6: Landing Zone Considerations

### 6.1 Service Control Policies (SCPs)

Ensure your landing zone SCPs allow:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole",
        "sts:AssumeRoleWithWebIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

### 6.2 VPC Endpoints (if using private subnets)

If your landing zone uses private subnets, create VPC endpoints:

```bash
# In each account
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxxxx \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-xxxxx
```

### 6.3 CloudTrail Logging

Enable CloudTrail in all accounts to audit cross-account access:

```bash
aws cloudtrail create-trail \
  --name amplify-cross-account-audit \
  --s3-bucket-name your-cloudtrail-bucket
```

## Step 7: Testing

### 7.1 Test Authentication

```bash
# Test Entra ID login
npm run dev
# Navigate to http://localhost:5173
# Click "Sign in with EntraID"
```

### 7.2 Test Cross-Account Access

Create file: `src/test/cross-account-test.ts`

```typescript
import { getCrossAccountS3Client } from '../utils/cross-account-storage';
import { ListObjectsV2Command } from '@aws-sdk/client-s3';
import { crossAccountBuckets } from '../config/cross-account-storage';

export async function testCrossAccountAccess() {
  try {
    const s3Client = await getCrossAccountS3Client(
      crossAccountBuckets.accountB.roleArn,
      crossAccountBuckets.accountB.region
    );

    const response = await s3Client.send(
      new ListObjectsV2Command({
        Bucket: crossAccountBuckets.accountB.bucket,
        MaxKeys: 10,
      })
    );

    console.log('✅ Cross-account access successful!');
    console.log('Objects:', response.Contents);
    return true;
  } catch (error) {
    console.error('❌ Cross-account access failed:', error);
    return false;
  }
}
```

## Troubleshooting

### Issue: "Access Denied" when assuming role

**Solution**: Verify the trust policy in the cross-account role includes your Identity Pool ID:

```bash
aws iam get-role --role-name AmplifyStorageCrossAccountRole --query 'Role.AssumeRolePolicyDocument'
```

### Issue: SAML authentication fails

**Solution**: Check Cognito User Pool SAML configuration:

```bash
aws cognito-idp describe-identity-provider \
  --user-pool-id us-east-1_XXXXXXXXX \
  --provider-name EntraID
```

### Issue: Landing zone SCP blocks access

**Solution**: Contact your cloud platform team to review SCPs. You may need an exception for:
- `sts:AssumeRole` between specific accounts
- `cognito-identity:GetCredentialsForIdentity`

### Issue: Bucket policy conflicts

**Solution**: Ensure bucket policies don't have explicit denies:

```bash
aws s3api get-bucket-policy --bucket your-bucket-name
```

## Security Best Practices

1. **Least Privilege**: Grant only necessary S3 permissions in cross-account roles
2. **MFA**: Enable MFA for Entra ID users accessing sensitive buckets
3. **Session Duration**: Keep AssumeRole session duration short (1 hour recommended)
4. **Audit Logging**: Enable CloudTrail in all accounts
5. **Bucket Encryption**: Use KMS encryption for S3 buckets
6. **VPC Endpoints**: Use VPC endpoints to keep traffic within AWS network
7. **Condition Keys**: Add condition keys to IAM policies for additional security

## Cost Considerations

- **STS AssumeRole calls**: ~$0.001 per 1,000 requests
- **S3 cross-account data transfer**: Standard S3 pricing applies
- **Cognito**: First 50,000 MAUs free, then $0.0055/MAU
- **CloudTrail**: First trail free, additional trails $2/month

## Additional Resources

- [AWS Amplify Gen 2 Documentation](https://docs.amplify.aws/react/)
- [Microsoft Entra ID SAML Configuration](https://docs.amplify.aws/react/build-a-backend/auth/examples/microsoft-entra-id-saml/)
- [Cross-Account S3 Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-walkthroughs-managing-access-example2.html)
- [AWS Landing Zone Best Practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/migration-aws-environment/understanding-landing-zones.html)

## Support

For issues specific to:
- **Amplify**: [AWS Amplify GitHub](https://github.com/aws-amplify/amplify-js/issues)
- **Entra ID**: [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/)
- **Landing Zone**: Contact your cloud platform team
