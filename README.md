# Amplify Storage Browser React+Vite Starter Template

This repository provides a starter template for creating applications with Storage Browser for S3 using React+Vite and AWS Amplify, emphasizing easy setup for authentication and S3 capabilities.

## Overview

This template equips you with a foundational React application integrated with AWS Amplify Auth and Storage Browser, streamlined for scalability and performance. It is ideal for developers looking to jumpstart their Storage Browser project with pre-configured AWS services like Cognito and S3.

## 🆕 Cross-Account & Enterprise Features

This template now includes support for:
- **Microsoft Entra ID (Azure AD) Authentication** via SAML
- **Cross-Account S3 Access** for multi-account AWS environments
- **Landing Zone Compatibility** for enterprise AWS deployments

📚 **See the guides:**
- [Quick Start Guide](QUICKSTART.md) - Get up and running in 75 minutes
- [Full Setup Guide](CROSS_ACCOUNT_SETUP.md) - Comprehensive documentation

## Features

- **Authentication**: Setup with Amazon Cognito for secure user authentication with email login.   
   - More info on how to setup and configuration option: https://docs.amplify.aws/react/build-a-backend/auth/set-up-auth/
- **Storage**: Configured with multiple S3 buckets and granular access controls. The sample is configured with
  - Default storage bucket with public, admin, and private access paths
  - Secondary storage bucket with separate backup paths.
  - More info on how to setup : https://docs.amplify.aws/react/build-a-backend/storage/set-up-storage/#building-your-storage-backend
- **UI Components**: Pre-integrated Amplify UI React components including:
  - Authenticator for sign-in/sign-up flows
      - More info : https://ui.docs.amplify.aws/react/connected-components/authenticator
  - Storage Browser for S3 file management.
      - More info : https://ui.docs.amplify.aws/react/connected-components/storage/storage-browser

## Project Structure

```
├── amplify/                  # Amplify Gen 2 backend configuration
│   ├── auth/                 # Authentication configuration
│   ├── storage/              # S3 storage configuration
│   ├── backend/              # Custom backend resources
│   │   └── custom-resources.ts  # Cross-account IAM configuration
│   └── backend.ts            # Main backend definition
├── src/
│   ├── config/               # Application configuration
│   │   └── cross-account-storage.ts  # Bucket configuration
│   ├── utils/                # Utility functions
│   │   └── cross-account-storage.ts  # S3 helper functions
│   ├── test/                 # Test files
│   │   └── cross-account-test.ts     # Cross-account tests
│   ├── App.tsx               # Main application component
│   └── main.tsx              # Application entry point
├── iam-policies/             # IAM policy templates
│   ├── account-b-*.json      # Account B policies
│   ├── account-c-*.json      # Account C policies
│   └── landing-zone-scp-requirements.json
├── scripts/                  # Deployment scripts
│   ├── deploy-cross-account-roles.sh
│   └── validate-setup.sh
├── QUICKSTART.md             # Quick start guide
├── CROSS_ACCOUNT_SETUP.md    # Full setup documentation
└── package.json              # Project dependencies
```

## Getting Started

### Basic Setup (Single Account)

1. Clone this repository
   ```bash
   git clone <repository-url>
   cd sample-amplify-storage-browser
   ```

2. Install dependencies
   ```bash
   npm install
   ```

3. Initialize and deploy the Amplify backend
   ```bash
   npx ampx sandbox
   ```

4. Start the development server
   ```bash
   npm run dev
   ```

### Cross-Account Setup (Multi-Account with Entra ID)

For enterprise deployments with multiple AWS accounts and Microsoft Entra ID:

1. **Validate your setup**
   ```bash
   ./scripts/validate-setup.sh
   ```

2. **Follow the Quick Start Guide**
   - See [QUICKSTART.md](QUICKSTART.md) for step-by-step instructions
   - Estimated time: 75 minutes

3. **Deploy cross-account roles**
   ```bash
   ./scripts/deploy-cross-account-roles.sh
   ```

4. **Test your setup**
   ```bash
   npm run dev
   # Then run tests in browser console
   ```

## Deploying to AWS

### Single Account Deployment

For detailed instructions on deploying your application, refer to the [deployment section](https://docs.amplify.aws/react/start/quickstart/#deploy-a-fullstack-app-to-aws) of our documentation.

### Multi-Account Deployment (Landing Zone)

For enterprise deployments across multiple AWS accounts:

1. **Review the architecture**
   - See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed diagrams

2. **Follow the setup checklist**
   - Use [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) to track progress

3. **Deploy using automation**
   ```bash
   ./scripts/deploy-cross-account-roles.sh
   ```

4. **Verify deployment**
   ```bash
   ./scripts/validate-setup.sh
   ```

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 75 minutes
- **[CROSS_ACCOUNT_SETUP.md](CROSS_ACCOUNT_SETUP.md)** - Comprehensive setup guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architecture diagrams and flows
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- **[SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)** - Step-by-step checklist
- **[SETUP_SUMMARY.md](SETUP_SUMMARY.md)** - Overview of all files created

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for more information.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.


_These sample applications are provided as a reference to help get started easily and are not supported by AWS Support._
