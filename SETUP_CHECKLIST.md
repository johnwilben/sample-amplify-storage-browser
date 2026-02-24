# Cross-Account Setup Checklist

Use this checklist to track your progress through the setup process.

## Pre-Setup Phase

### Prerequisites
- [ ] AWS Landing Zone or Control Tower configured
- [ ] Microsoft Entra ID tenant with admin access
- [ ] Three AWS accounts identified:
  - [ ] Account A (Amplify): `_______________`
  - [ ] Account B (Storage): `_______________`
  - [ ] Account C (Storage): `_______________`
- [ ] Node.js 18+ installed
- [ ] AWS CLI installed and configured
- [ ] jq installed (for JSON processing)
- [ ] Git repository cloned

### Account Access
- [ ] AWS CLI profile configured for Account A
- [ ] AWS CLI profile configured for Account B
- [ ] AWS CLI profile configured for Account C
- [ ] Verified access with `aws sts get-caller-identity` for each account

### Permissions Verification
- [ ] Account A: Can create Cognito resources
- [ ] Account A: Can create S3 buckets
- [ ] Account A: Can create IAM roles
- [ ] Account B: Can create IAM roles
- [ ] Account B: Can modify S3 bucket policies
- [ ] Account C: Can create IAM roles
- [ ] Account C: Can modify S3 bucket policies

## Phase 1: Microsoft Entra ID Configuration (15 minutes)

### Create Enterprise Application
- [ ] Logged into [Entra Admin Center](https://entra.microsoft.com)
- [ ] Navigated to Identity > Applications > Enterprise applications
- [ ] Created new application: "Amplify Storage Browser"
- [ ] Selected "Integrate any other application"
- [ ] Application created successfully

### Initial SAML Setup
- [ ] Opened Single sign-on settings
- [ ] Selected SAML as authentication method
- [ ] Noted that configuration will be completed after Amplify deployment

### User Assignment
- [ ] Navigated to Users and groups
- [ ] Added test users to application
- [ ] Verified users can see application in their portal

**Checkpoint**: Enterprise application created and users assigned

## Phase 2: Amplify Backend Deployment (10 minutes)

### Install Dependencies
- [ ] Ran `npm install`
- [ ] Verified all dependencies installed successfully
- [ ] No errors in package installation

### Initial Deployment
- [ ] Ran `npx ampx sandbox`
- [ ] Deployment completed successfully
- [ ] Noted the following values:
  - [ ] Cognito User Pool ID: `_______________________`
  - [ ] Cognito Identity Pool ID: `_______________________`
  - [ ] User Pool Domain: `_______________________`
  - [ ] Region: `_______________________`

### Verify Resources Created
- [ ] Cognito User Pool exists in AWS Console
- [ ] Cognito Identity Pool exists in AWS Console
- [ ] S3 buckets created (myStorageBucket, mySecondaryStorageBucket)
- [ ] IAM roles created for authenticated users

**Checkpoint**: Amplify backend deployed successfully

## Phase 3: Complete Entra ID SAML Configuration (10 minutes)

### Basic SAML Configuration
- [ ] Returned to Entra Admin Center
- [ ] Opened SAML configuration for application
- [ ] Set Identifier (Entity ID): `urn:amazon:cognito:sp:<USER_POOL_ID>`
- [ ] Set Reply URL: `https://<USER_POOL_DOMAIN>/saml2/idpresponse`
- [ ] Saved configuration

### Attributes & Claims
- [ ] Added email claim: `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress` → `user.mail`
- [ ] Added name claim: `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name` → `user.userprincipalname`
- [ ] Saved claims configuration

### Federation Metadata
- [ ] Downloaded Federation Metadata XML
- [ ] Noted metadata URL: `_______________________`
- [ ] Verified metadata is accessible

### Update Amplify Auth Configuration
- [ ] Updated `amplify/auth/resource.ts` with Entra ID metadata URL
- [ ] Redeployed: `npx ampx sandbox`
- [ ] Verified SAML provider created in Cognito

**Checkpoint**: SAML authentication configured

## Phase 4: Cross-Account IAM Roles (20 minutes)

### Prepare Configuration
- [ ] Opened `config-template.env`
- [ ] Filled in all required values
- [ ] Saved as `.env` (not committed to git)

### Run Validation
- [ ] Ran `./scripts/validate-setup.sh`
- [ ] Resolved any errors
- [ ] Confirmed all checks passed

### Deploy to Account B
- [ ] Switched to Account B AWS profile
- [ ] Ran `./scripts/deploy-cross-account-roles.sh`
- [ ] Provided required information:
  - [ ] Cognito Identity Pool ID
  - [ ] Account B ID
  - [ ] Account B Bucket Name
- [ ] Verified role created: `AmplifyStorageCrossAccountRole`
- [ ] Verified bucket policy applied
- [ ] Noted Role ARN: `_______________________`

### Deploy to Account C
- [ ] Switched to Account C AWS profile
- [ ] Continued with deployment script
- [ ] Provided required information:
  - [ ] Account C ID
  - [ ] Account C Bucket Name
- [ ] Verified role created: `AmplifyStorageCrossAccountRole`
- [ ] Verified bucket policy applied
- [ ] Noted Role ARN: `_______________________`

### Verify Roles
- [ ] Checked trust policy in Account B role
- [ ] Checked trust policy in Account C role
- [ ] Verified Identity Pool ID matches in both
- [ ] Verified S3 permissions are correct

**Checkpoint**: Cross-account IAM roles deployed

## Phase 5: Update Application Configuration (5 minutes)

### Update Backend Configuration
- [ ] Opened `amplify/backend/custom-resources.ts`
- [ ] Replaced example account IDs with actual values:
  - [ ] Account B: `222222222222` → `_______________`
  - [ ] Account C: `333333333333` → `_______________`
- [ ] Saved file

### Update Storage Configuration
- [ ] Opened `src/config/cross-account-storage.ts`
- [ ] Updated Account B configuration:
  - [ ] Bucket name
  - [ ] Region
  - [ ] Role ARN
  - [ ] Account ID
- [ ] Updated Account C configuration:
  - [ ] Bucket name
  - [ ] Region
  - [ ] Role ARN
  - [ ] Account ID
- [ ] Saved file

### Enable Cross-Account Access
- [ ] Opened `amplify/backend.ts`
- [ ] Uncommented: `addCrossAccountAccess(backend);`
- [ ] Saved file

### Redeploy Amplify
- [ ] Ran `npx ampx sandbox`
- [ ] Deployment completed successfully
- [ ] Verified no errors in deployment logs

**Checkpoint**: Application configured for cross-account access

## Phase 6: Testing (15 minutes)

### Start Development Server
- [ ] Ran `npm run dev`
- [ ] Application started successfully
- [ ] Opened browser to `http://localhost:5173`

### Test Authentication
- [ ] Clicked "Sign in with EntraID"
- [ ] Redirected to Entra ID login page
- [ ] Entered credentials
- [ ] Completed MFA (if required)
- [ ] Successfully redirected back to application
- [ ] User authenticated and session active

### Test Same-Account Access
- [ ] Verified can access default storage bucket
- [ ] Uploaded test file
- [ ] Downloaded test file
- [ ] Deleted test file
- [ ] All operations successful

### Test Cross-Account Access (Account B)
- [ ] Opened browser console
- [ ] Ran test: `import { testCrossAccountAccess } from './src/test/cross-account-test'; await testCrossAccountAccess();`
- [ ] Account B access successful
- [ ] Can list objects in Account B bucket
- [ ] Can upload to Account B bucket
- [ ] Can download from Account B bucket
- [ ] Can delete from Account B bucket

### Test Cross-Account Access (Account C)
- [ ] Account C access successful
- [ ] Can list objects in Account C bucket
- [ ] Can upload to Account C bucket
- [ ] Can download from Account C bucket
- [ ] Can delete from Account C bucket

### Test User-Specific Paths
- [ ] Ran test: `import { testUserSpecificAccess } from './src/test/cross-account-test'; await testUserSpecificAccess();`
- [ ] Can access private/{identity_id}/* path
- [ ] Cannot access other users' private paths
- [ ] Path isolation working correctly

**Checkpoint**: All tests passing

## Phase 7: Landing Zone Verification (Optional)

### Service Control Policies
- [ ] Verified SCPs allow required actions
- [ ] No SCP violations in CloudTrail
- [ ] Requested exceptions if needed

### Control Tower Guardrails
- [ ] Checked Control Tower dashboard
- [ ] No guardrail violations
- [ ] All accounts in compliance

### Network Configuration
- [ ] VPC endpoints configured (if required)
- [ ] Network connectivity verified
- [ ] No timeout errors

**Checkpoint**: Landing zone compliance verified

## Phase 8: Production Preparation

### Security Hardening
- [ ] Enabled CloudTrail in all accounts
- [ ] Configured S3 access logging
- [ ] Enabled Cognito advanced security features
- [ ] Reviewed and tightened IAM policies
- [ ] Enabled MFA for sensitive operations

### Monitoring Setup
- [ ] Created CloudWatch dashboards
- [ ] Set up alarms for failed authentications
- [ ] Set up alarms for access denied errors
- [ ] Configured SNS notifications

### Documentation
- [ ] Documented account IDs and role ARNs
- [ ] Created runbook for common operations
- [ ] Documented troubleshooting steps
- [ ] Shared documentation with team

### Backup and Recovery
- [ ] Documented backup procedures
- [ ] Tested credential rotation
- [ ] Verified disaster recovery plan
- [ ] Documented rollback procedures

**Checkpoint**: Production ready

## Post-Deployment

### User Training
- [ ] Trained users on authentication flow
- [ ] Demonstrated file upload/download
- [ ] Explained access controls
- [ ] Provided user documentation

### Monitoring
- [ ] Monitoring dashboards reviewed daily
- [ ] No unexpected errors
- [ ] Performance within acceptable limits
- [ ] Cost tracking enabled

### Maintenance
- [ ] Scheduled regular security reviews
- [ ] Planned credential rotation schedule
- [ ] Documented update procedures
- [ ] Established support process

## Troubleshooting Reference

If you encounter issues, refer to:
- [ ] [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues and solutions
- [ ] [CROSS_ACCOUNT_SETUP.md](./CROSS_ACCOUNT_SETUP.md) - Detailed setup guide
- [ ] [ARCHITECTURE.md](./ARCHITECTURE.md) - Architecture diagrams and flows

## Success Criteria

✅ Setup is complete when:
- [ ] Users can authenticate via Entra ID
- [ ] Users can access buckets in Account A (same account)
- [ ] Users can access buckets in Account B (cross-account)
- [ ] Users can access buckets in Account C (cross-account)
- [ ] User-specific paths are isolated
- [ ] All security controls are in place
- [ ] Monitoring is active
- [ ] Documentation is complete

## Estimated Time

- Pre-Setup: 15 minutes
- Phase 1: 15 minutes
- Phase 2: 10 minutes
- Phase 3: 10 minutes
- Phase 4: 20 minutes
- Phase 5: 5 minutes
- Phase 6: 15 minutes
- Phase 7: 10 minutes (optional)
- Phase 8: 30 minutes

**Total: ~75-90 minutes** (excluding production preparation)

## Notes

Use this space to track any issues, decisions, or important information:

```
Date: _______________
Notes:
_____________________________________________________________________
_____________________________________________________________________
_____________________________________________________________________
_____________________________________________________________________
_____________________________________________________________________
```

## Sign-Off

- [ ] Setup completed by: _______________
- [ ] Date: _______________
- [ ] Reviewed by: _______________
- [ ] Date: _______________
- [ ] Approved for production: _______________
- [ ] Date: _______________
