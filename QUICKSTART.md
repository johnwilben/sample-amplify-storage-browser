# Quick Start Guide - Cross-Account Setup

This is a condensed version of the full setup guide. For detailed instructions, see [CROSS_ACCOUNT_SETUP.md](./CROSS_ACCOUNT_SETUP.md).

## Prerequisites Checklist

- [ ] AWS Landing Zone or Control Tower configured
- [ ] Microsoft Entra ID tenant with admin access
- [ ] Three AWS accounts ready:
  - Account A (Amplify): `_______________`
  - Account B (Storage): `_______________`
  - Account C (Storage): `_______________`
- [ ] Node.js 18+ installed
- [ ] AWS CLI configured with profiles for all accounts

## 5-Step Setup

### Step 1: Configure Entra ID (15 minutes)

1. Go to [Entra Admin Center](https://entra.microsoft.com)
2. Create new Enterprise Application: "Amplify Storage Browser"
3. Configure SAML (you'll complete this after Step 2)
4. Assign users to the application

### Step 2: Deploy Amplify Backend (10 minutes)

```bash
# Install dependencies
npm install

# Deploy to sandbox
npx ampx sandbox
```

**Save these values from the output:**
- Cognito User Pool ID: `_______________________`
- Cognito Identity Pool ID: `_______________________`
- User Pool Domain: `_______________________`

### Step 3: Complete Entra ID SAML (10 minutes)

Back in Entra Admin Center:

1. **Basic SAML Configuration**:
   - Entity ID: `urn:amazon:cognito:sp:<USER_POOL_ID>`
   - Reply URL: `https://<USER_POOL_DOMAIN>/saml2/idpresponse`

2. **Attributes & Claims**:
   - Email: `user.mail`
   - Name: `user.userprincipalname`

3. Download Federation Metadata XML

### Step 4: Deploy Cross-Account Roles (20 minutes)

```bash
# Make script executable (already done)
chmod +x scripts/deploy-cross-account-roles.sh

# Run deployment script
./scripts/deploy-cross-account-roles.sh
```

The script will prompt you for:
- Cognito Identity Pool ID
- Account B ID and bucket name
- Account C ID and bucket name
- AWS Region

**Important**: You'll need to switch AWS profiles when prompted.

### Step 5: Update Configuration (5 minutes)

1. **Update `amplify/backend/custom-resources.ts`**:
   ```typescript
   const crossAccountRoles = [
     'arn:aws:iam::YOUR_ACCOUNT_B_ID:role/AmplifyStorageCrossAccountRole',
     'arn:aws:iam::YOUR_ACCOUNT_C_ID:role/AmplifyStorageCrossAccountRole',
   ];
   ```

2. **Update `src/config/cross-account-storage.ts`**:
   ```typescript
   accountB: {
     bucket: 'your-actual-bucket-name',
     region: 'us-east-1',
     roleArn: 'arn:aws:iam::YOUR_ACCOUNT_B_ID:role/AmplifyStorageCrossAccountRole',
     accountId: 'YOUR_ACCOUNT_B_ID',
   },
   ```

3. **Uncomment in `amplify/backend.ts`**:
   ```typescript
   addCrossAccountAccess(backend);
   ```

4. **Redeploy**:
   ```bash
   npx ampx sandbox
   ```

## Testing

```bash
# Start dev server
npm run dev

# Open browser to http://localhost:5173
# Sign in with Entra ID
# Test cross-account access in browser console:
```

```javascript
import { runAllTests } from './src/test/cross-account-test';
runAllTests();
```

## Troubleshooting Quick Fixes

### "Access Denied" when assuming role
```bash
# Verify trust policy
aws iam get-role --role-name AmplifyStorageCrossAccountRole
```

### SAML authentication fails
```bash
# Check Cognito SAML config
aws cognito-idp describe-identity-provider \
  --user-pool-id YOUR_POOL_ID \
  --provider-name EntraID
```

### Can't list bucket objects
```bash
# Verify bucket policy
aws s3api get-bucket-policy --bucket your-bucket-name
```

## Landing Zone Considerations

If you're in a landing zone, ensure your SCPs allow:
- `sts:AssumeRole` between accounts
- `sts:AssumeRoleWithWebIdentity`
- `cognito-identity:GetCredentialsForIdentity`

Contact your cloud platform team if you encounter SCP-related errors.

## Configuration Files Reference

| File | Purpose |
|------|---------|
| `iam-policies/account-b-trust-policy.json` | Trust policy for Account B role |
| `iam-policies/account-b-s3-permissions.json` | S3 permissions for Account B |
| `iam-policies/account-b-bucket-policy.json` | Bucket policy for Account B |
| `amplify/backend/custom-resources.ts` | Cross-account IAM permissions |
| `src/config/cross-account-storage.ts` | Bucket configuration |
| `src/utils/cross-account-storage.ts` | Helper functions |

## Next Steps

After successful setup:

1. Configure additional buckets by adding to `crossAccountBuckets`
2. Implement Storage Browser UI components
3. Add user-specific path restrictions
4. Enable CloudTrail logging for audit
5. Set up monitoring and alerts

## Support

- Full documentation: [CROSS_ACCOUNT_SETUP.md](./CROSS_ACCOUNT_SETUP.md)
- AWS Amplify: https://docs.amplify.aws/
- Entra ID: https://learn.microsoft.com/en-us/entra/

## Estimated Total Time

- Initial setup: ~60 minutes
- Testing and validation: ~15 minutes
- **Total: ~75 minutes**
