# Your Entra ID Setup Guide

## Your Entra ID Details

- **Tenant ID**: `84955449-af74-4a26-a735-f573b47d98ba`
- **Application Name**: Amplify-S3Browser-Test
- **Application (client) ID**: `430a9859-5923-4749-8313-f8c74bc509cf`
- **Federation Metadata URL**: `https://login.microsoftonline.com/84955449-af74-4a26-a735-f573b47d98ba/federationmetadata/2007-06/federationmetadata.xml`
- **AWS Region**: `ap-southeast-1` (Singapore)

✅ **Already configured in**: `amplify/auth/resource.ts`

## Step-by-Step Setup

### Step 1: Deploy Amplify to Get Cognito Pool IDs

```bash
# Install dependencies (if not done)
npm install

# Deploy Amplify backend
npx ampx sandbox
```

Wait for deployment to complete (5-10 minutes).

### Step 2: Get Your Cognito Pool IDs

```bash
# Run the helper script
./scripts/get-cognito-ids.sh
```

This will output:
- **User Pool ID**: `ap-southeast-1_XXXXXXXXX`
- **Identity Pool ID**: `ap-southeast-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **Entity ID** for Entra ID
- **Reply URL** for Entra ID

**Save these values!** You'll need them for the next steps.

### Step 3: Configure SAML in Entra ID

1. Go to [Entra Admin Center](https://entra.microsoft.com)
2. Navigate to your application: **Amplify-S3Browser-Test**
3. Click **Single sign-on** > **SAML**
4. Click **Edit** on Basic SAML Configuration

**Enter these values** (from Step 2 output):

- **Identifier (Entity ID)**: `urn:amazon:cognito:sp:<YOUR_USER_POOL_ID>`
- **Reply URL**: `https://<YOUR_DOMAIN>.auth.ap-southeast-1.amazoncognito.com/saml2/idpresponse`

5. Click **Save**

### Step 4: Configure Attributes & Claims

Still in Entra ID SAML configuration:

1. Click **Edit** on Attributes & Claims
2. Add these claims:

| Claim Name | Source Attribute |
|------------|------------------|
| `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress` | `user.mail` |
| `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name` | `user.userprincipalname` |

3. Click **Save**

### Step 5: Assign Users

1. In Entra ID, go to your application
2. Click **Users and groups**
3. Click **Add user/group**
4. Select users who should have access
5. Click **Assign**

### Step 6: Test Authentication

```bash
# Start dev server
npm run dev
```

1. Open browser to `http://localhost:5173`
2. Click "Sign in with EntraID"
3. You should be redirected to Microsoft login
4. Sign in with your Entra ID credentials
5. You should be redirected back to the app

✅ If successful, you're authenticated!

### Step 7: Set Up Cross-Account Access (Optional)

If you need to access S3 buckets in other AWS accounts:

1. **Get your account IDs**:
   - Account A (Amplify): `_______________`
   - Account B (Storage): `_______________`
   - Account C (Storage): `_______________`

2. **Run the deployment script**:
   ```bash
   ./scripts/deploy-cross-account-roles.sh
   ```

3. **Follow the prompts** and provide:
   - Identity Pool ID (from Step 2)
   - Account IDs
   - Bucket names

4. **Update configuration files**:
   - `amplify/backend/custom-resources.ts` - Add your account IDs
   - `src/config/cross-account-storage.ts` - Add bucket names and role ARNs

5. **Redeploy**:
   ```bash
   npx ampx sandbox
   ```

## Quick Commands Reference

```bash
# Get Cognito IDs
./scripts/get-cognito-ids.sh

# Validate setup
./scripts/validate-setup.sh

# Deploy cross-account roles
./scripts/deploy-cross-account-roles.sh

# Start dev server
npm run dev

# Deploy Amplify
npx ampx sandbox
```

## Troubleshooting

### "No User Pool found"
- Make sure you've run `npx ampx sandbox` first
- Check that deployment completed successfully

### SAML authentication fails
- Verify Entity ID and Reply URL in Entra ID match Cognito values
- Check that users are assigned to the application
- Verify federation metadata URL is accessible

### Can't access S3 buckets
- Make sure you've completed authentication first
- Check that bucket policies allow your Cognito role
- Verify IAM permissions are correct

## Need Help?

- **Full documentation**: See `CROSS_ACCOUNT_SETUP.md`
- **Quick start**: See `QUICKSTART.md`
- **Troubleshooting**: See `TROUBLESHOOTING.md`
- **Architecture**: See `ARCHITECTURE.md`

## Current Status

- [x] Entra ID tenant ID configured
- [x] Auth resource updated with SAML
- [ ] Amplify deployed
- [ ] Cognito Pool IDs obtained
- [ ] Entra ID SAML configured
- [ ] Users assigned
- [ ] Authentication tested
- [ ] Cross-account setup (if needed)

## Next Step

👉 **Run**: `npm install && npx ampx sandbox`

Then run `./scripts/get-cognito-ids.sh` to get your Pool IDs!
