# Architecture Overview - Cross-Account S3 Access

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         End User (Browser)                              │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │              React App (Amplify Storage Browser)                  │ │
│  │  - Authentication UI                                              │ │
│  │  - File Browser UI                                                │ │
│  │  - Upload/Download Components                                     │ │
│  └──────────────────────────────────────────────────────────────────┘ │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ 1. User Login
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     Microsoft Entra ID (Azure AD)                       │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │  - Enterprise User Directory                                     │ │
│  │  - SAML Identity Provider                                        │ │
│  │  - Group Management                                              │ │
│  │  - MFA & Conditional Access                                      │ │
│  └──────────────────────────────────────────────────────────────────┘ │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ 2. SAML Assertion
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    AWS Account A (Amplify Account)                      │
│                         Account ID: 111111111111                        │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                    Amazon Cognito                                 │ │
│  │                                                                   │ │
│  │  ┌────────────────────┐        ┌────────────────────┐           │ │
│  │  │  User Pool         │        │  Identity Pool     │           │ │
│  │  │  - SAML Provider   │───────▶│  - Federated Auth  │           │ │
│  │  │  - User Attributes │        │  - AWS Credentials │           │ │
│  │  └────────────────────┘        └────────────────────┘           │ │
│  │                                          │                        │ │
│  └──────────────────────────────────────────┼────────────────────────┘ │
│                                             │                          │
│  ┌──────────────────────────────────────────┼────────────────────────┐ │
│  │              IAM Authenticated Role      │                        │ │
│  │                                          │                        │ │
│  │  Permissions:                            │                        │ │
│  │  - sts:AssumeRole (cross-account)       │                        │ │
│  │  - cognito-identity:GetCredentials      │                        │ │
│  └──────────────────────────────────────────┼────────────────────────┘ │
│                                             │                          │
│  ┌──────────────────────────────────────────┼────────────────────────┐ │
│  │              Amplify Backend             │                        │ │
│  │  - Auth Configuration                    │                        │ │
│  │  - Storage Configuration                 │                        │ │
│  │  - Custom Resources (CDK)                │                        │ │
│  └──────────────────────────────────────────┼────────────────────────┘ │
└─────────────────────────────────────────────┼──────────────────────────┘
                                              │
                                              │ 3. AssumeRole
                                              │
                        ┌─────────────────────┴─────────────────────┐
                        │                                           │
                        ▼                                           ▼
┌───────────────────────────────────────┐  ┌───────────────────────────────────────┐
│  AWS Account B (Storage Account 1)   │  │  AWS Account C (Storage Account 2)   │
│  Account ID: 222222222222             │  │  Account ID: 333333333333             │
│                                       │  │                                       │
│  ┌─────────────────────────────────┐ │  │  ┌─────────────────────────────────┐ │
│  │  IAM Cross-Account Role         │ │  │  │  IAM Cross-Account Role         │ │
│  │  AmplifyStorageCrossAccountRole │ │  │  │  AmplifyStorageCrossAccountRole │ │
│  │                                 │ │  │  │                                 │ │
│  │  Trust Policy:                  │ │  │  │  Trust Policy:                  │ │
│  │  - Cognito Identity Pool        │ │  │  │  - Cognito Identity Pool        │ │
│  │                                 │ │  │  │                                 │ │
│  │  Permissions:                   │ │  │  │  Permissions:                   │ │
│  │  - s3:GetObject                 │ │  │  │  - s3:GetObject                 │ │
│  │  - s3:PutObject                 │ │  │  │  - s3:PutObject                 │ │
│  │  - s3:DeleteObject              │ │  │  │  - s3:DeleteObject              │ │
│  │  - s3:ListBucket                │ │  │  │  - s3:ListBucket                │ │
│  └─────────────────────────────────┘ │  │  └─────────────────────────────────┘ │
│                │                      │  │                │                      │
│                │ 4. S3 Access          │  │                │ 4. S3 Access          │
│                ▼                      │  │                ▼                      │
│  ┌─────────────────────────────────┐ │  │  ┌─────────────────────────────────┐ │
│  │  S3 Bucket                      │ │  │  │  S3 Bucket                      │ │
│  │  your-bucket-name-account-b     │ │  │  │  your-bucket-name-account-c     │ │
│  │                                 │ │  │  │                                 │ │
│  │  Paths:                         │ │  │  │  Paths:                         │ │
│  │  - public/*                     │ │  │  │  - public/*                     │ │
│  │  - admin/*                      │ │  │  │  - admin/*                      │ │
│  │  - private/{identity_id}/*      │ │  │  │  - private/{identity_id}/*      │ │
│  │                                 │ │  │  │                                 │ │
│  │  Bucket Policy:                 │ │  │  │  Bucket Policy:                 │ │
│  │  - Allow cross-account role     │ │  │  │  - Allow cross-account role     │ │
│  │  - Enforce encryption           │ │  │  │  - Enforce encryption           │ │
│  └─────────────────────────────────┘ │  │  └─────────────────────────────────┘ │
└───────────────────────────────────────┘  └───────────────────────────────────────┘
```

## Authentication Flow

```
┌──────┐                                                    ┌──────────────┐
│ User │                                                    │  Entra ID    │
└───┬──┘                                                    └──────┬───────┘
    │                                                              │
    │ 1. Click "Sign in with Entra ID"                           │
    ├─────────────────────────────────────────────────────────────▶
    │                                                              │
    │ 2. Redirect to Entra ID login page                          │
    ◀─────────────────────────────────────────────────────────────┤
    │                                                              │
    │ 3. Enter credentials + MFA                                  │
    ├─────────────────────────────────────────────────────────────▶
    │                                                              │
    │ 4. SAML Assertion (if authenticated)                        │
    ◀─────────────────────────────────────────────────────────────┤
    │                                                              │
    ▼                                                              │
┌──────────────┐                                                  │
│   Cognito    │                                                  │
│  User Pool   │                                                  │
└───┬──────────┘                                                  │
    │                                                              │
    │ 5. Validate SAML assertion                                  │
    │                                                              │
    │ 6. Create/update user in User Pool                          │
    │                                                              │
    ▼                                                              │
┌──────────────┐                                                  │
│   Cognito    │                                                  │
│Identity Pool │                                                  │
└───┬──────────┘                                                  │
    │                                                              │
    │ 7. Exchange for AWS credentials                             │
    │                                                              │
    │ 8. Return temporary credentials                             │
    │    - Access Key ID                                          │
    │    - Secret Access Key                                      │
    │    - Session Token                                          │
    │    - Identity ID                                            │
    │                                                              │
    ▼                                                              │
┌──────┐                                                          │
│ User │ (Now has AWS credentials)                               │
└──────┘                                                          │
```

## Cross-Account Access Flow

```
┌──────────────┐
│  React App   │
└──────┬───────┘
       │
       │ 1. User wants to access Account B bucket
       │
       ▼
┌──────────────────────────────────────────┐
│  getCrossAccountS3Client()               │
│  (src/utils/cross-account-storage.ts)   │
└──────┬───────────────────────────────────┘
       │
       │ 2. Get current Cognito credentials
       │
       ▼
┌──────────────────────────────────────────┐
│  fetchAuthSession()                      │
│  Returns: credentials + identityId       │
└──────┬───────────────────────────────────┘
       │
       │ 3. Create STS client with Cognito credentials
       │
       ▼
┌──────────────────────────────────────────┐
│  STS AssumeRole                          │
│  RoleArn: arn:aws:iam::222222222222:    │
│           role/AmplifyStorage...         │
└──────┬───────────────────────────────────┘
       │
       │ 4. Validate trust policy in Account B
       │    - Check Identity Pool ID
       │    - Verify authenticated user
       │
       ▼
┌──────────────────────────────────────────┐
│  Account B IAM Role                      │
│  Returns temporary credentials:          │
│  - Access Key ID                         │
│  - Secret Access Key                     │
│  - Session Token                         │
│  - Expiration (1 hour)                   │
└──────┬───────────────────────────────────┘
       │
       │ 5. Create S3 client with assumed role credentials
       │
       ▼
┌──────────────────────────────────────────┐
│  S3 Client (Account B)                   │
│  Can now access bucket in Account B      │
└──────┬───────────────────────────────────┘
       │
       │ 6. Perform S3 operations
       │    - ListObjects
       │    - GetObject
       │    - PutObject
       │    - DeleteObject
       │
       ▼
┌──────────────────────────────────────────┐
│  S3 Bucket (Account B)                   │
│  Validates:                              │
│  - Bucket policy allows role             │
│  - IAM permissions on role               │
│  - Path-based access (if applicable)     │
└──────────────────────────────────────────┘
```

## Security Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                        Security Layer 1                         │
│                   Microsoft Entra ID                            │
│  - User authentication                                          │
│  - Multi-factor authentication (MFA)                            │
│  - Conditional access policies                                  │
│  - Group-based access control                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Security Layer 2                         │
│                      Amazon Cognito                             │
│  - SAML assertion validation                                    │
│  - User pool policies                                           │
│  - Identity pool authentication                                 │
│  - Temporary credential issuance                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Security Layer 3                         │
│                    IAM Trust Policies                           │
│  - Verify Identity Pool ID                                      │
│  - Validate authenticated status                                │
│  - Check SAML attributes                                        │
│  - Enforce session duration                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Security Layer 4                         │
│                    IAM Role Permissions                         │
│  - Least privilege S3 access                                    │
│  - Resource-level permissions                                   │
│  - Condition keys for fine-grained control                      │
│  - Action-level restrictions                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Security Layer 5                         │
│                      S3 Bucket Policies                         │
│  - Cross-account access control                                 │
│  - Encryption enforcement                                       │
│  - Path-based restrictions                                      │
│  - Deny overrides                                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Security Layer 6                         │
│                  Landing Zone Controls                          │
│  - Service Control Policies (SCPs)                              │
│  - Control Tower guardrails                                     │
│  - Organization policies                                        │
│  - Compliance requirements                                      │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow - File Upload Example

```
User uploads file to Account B bucket:

1. User selects file in browser
   └─▶ React component captures file

2. App calls putCrossAccountObject()
   └─▶ src/utils/cross-account-storage.ts

3. Get Cognito credentials
   └─▶ fetchAuthSession()
   └─▶ Returns: accessKeyId, secretAccessKey, sessionToken

4. Create STS client
   └─▶ new STSClient({ credentials: cognitoCredentials })

5. Assume cross-account role
   └─▶ AssumeRoleCommand({
       RoleArn: "arn:aws:iam::222222222222:role/...",
       RoleSessionName: "amplify-storage-session"
   })

6. Receive temporary credentials for Account B
   └─▶ accessKeyId, secretAccessKey, sessionToken (1 hour expiry)

7. Create S3 client with assumed role credentials
   └─▶ new S3Client({ credentials: assumedRoleCredentials })

8. Upload file
   └─▶ PutObjectCommand({
       Bucket: "your-bucket-name-account-b",
       Key: "private/us-east-1:xxx-xxx/myfile.pdf",
       Body: fileData,
       ServerSideEncryption: "AES256"
   })

9. S3 validates request
   ├─▶ Check bucket policy (allows cross-account role)
   ├─▶ Check IAM permissions (role has PutObject)
   ├─▶ Check path access (user can write to private/{identity_id}/*)
   └─▶ Enforce encryption (AES256 required)

10. File stored successfully
    └─▶ Return ETag and metadata to app
```

## Component Interaction

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend Layer                          │
├─────────────────────────────────────────────────────────────────┤
│  App.tsx                                                        │
│  └─▶ Authenticator (Amplify UI)                                │
│      └─▶ StorageBrowser (Amplify UI)                           │
│          └─▶ Custom cross-account components                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Configuration Layer                        │
├─────────────────────────────────────────────────────────────────┤
│  src/config/cross-account-storage.ts                           │
│  - Bucket names                                                 │
│  - Role ARNs                                                    │
│  - Account IDs                                                  │
│  - Regions                                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Utility Layer                           │
├─────────────────────────────────────────────────────────────────┤
│  src/utils/cross-account-storage.ts                           │
│  - getCrossAccountS3Client()                                    │
│  - listCrossAccountObjects()                                    │
│  - getCrossAccountObject()                                      │
│  - putCrossAccountObject()                                      │
│  - deleteCrossAccountObject()                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          AWS SDK Layer                          │
├─────────────────────────────────────────────────────────────────┤
│  @aws-sdk/client-sts                                           │
│  - AssumeRoleCommand                                            │
│                                                                 │
│  @aws-sdk/client-s3                                            │
│  - ListObjectsV2Command                                         │
│  - GetObjectCommand                                             │
│  - PutObjectCommand                                             │
│  - DeleteObjectCommand                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Backend Layer                           │
├─────────────────────────────────────────────────────────────────┤
│  amplify/backend.ts                                            │
│  └─▶ auth (Cognito)                                            │
│  └─▶ storage (S3 - same account)                               │
│  └─▶ custom-resources (cross-account IAM)                      │
└─────────────────────────────────────────────────────────────────┘
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Development Phase                          │
├─────────────────────────────────────────────────────────────────┤
│  1. Configure Entra ID                                          │
│     └─▶ Create enterprise application                          │
│     └─▶ Configure SAML                                          │
│                                                                 │
│  2. Deploy Amplify Backend (Account A)                         │
│     └─▶ npx ampx sandbox                                       │
│     └─▶ Creates: Cognito, S3, IAM roles                        │
│                                                                 │
│  3. Deploy Cross-Account Roles (Accounts B & C)                │
│     └─▶ ./scripts/deploy-cross-account-roles.sh               │
│     └─▶ Creates: IAM roles, bucket policies                    │
│                                                                 │
│  4. Update Configuration                                        │
│     └─▶ Update custom-resources.ts                             │
│     └─▶ Update cross-account-storage.ts                        │
│                                                                 │
│  5. Redeploy Amplify                                           │
│     └─▶ npx ampx sandbox                                       │
│     └─▶ Applies cross-account permissions                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Testing Phase                             │
├─────────────────────────────────────────────────────────────────┤
│  1. Validate Setup                                              │
│     └─▶ ./scripts/validate-setup.sh                           │
│                                                                 │
│  2. Test Authentication                                         │
│     └─▶ Sign in with Entra ID                                  │
│                                                                 │
│  3. Test Cross-Account Access                                   │
│     └─▶ Run test suite                                          │
│     └─▶ Verify bucket access                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Production Phase                           │
├─────────────────────────────────────────────────────────────────┤
│  1. Deploy to Production                                        │
│     └─▶ npx ampx pipeline-deploy --branch main                │
│                                                                 │
│  2. Configure Custom Domain                                     │
│     └─▶ Set up CloudFront + Route53                            │
│                                                                 │
│  3. Enable Monitoring                                           │
│     └─▶ CloudWatch dashboards                                   │
│     └─▶ CloudTrail logging                                      │
│     └─▶ Alerts and notifications                                │
└─────────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Why STS AssumeRole?
- Temporary credentials (1 hour expiry)
- No long-lived access keys
- Centralized credential management
- Audit trail via CloudTrail

### 2. Why Cognito Identity Pool?
- Seamless integration with Amplify
- Automatic credential vending
- Support for federated identities
- Built-in user isolation

### 3. Why Separate Accounts?
- Security isolation
- Billing separation
- Compliance requirements
- Blast radius limitation

### 4. Why Entra ID SAML?
- Enterprise SSO
- Centralized user management
- MFA and conditional access
- Group-based authorization

## Performance Considerations

- **Credential Caching**: Assumed role credentials cached for 1 hour
- **Connection Pooling**: S3 client reuses connections
- **Parallel Operations**: Multiple bucket access in parallel
- **Regional Endpoints**: Use region-specific S3 endpoints

## Cost Optimization

- **STS Calls**: Minimize by caching credentials
- **S3 Requests**: Batch operations when possible
- **Data Transfer**: Use same-region buckets when possible
- **CloudTrail**: Use organization trail for all accounts
