# Amplify Storage Browser React+Vite Starter Template

This repository provides a starter template for creating applications with Storage Browser for S3 using React+Vite and AWS Amplify, emphasizing easy setup for authentication and S3 capabilities.

## Overview

This template equips you with a foundational React application integrated with AWS Amplify Auth and Storage Browser, streamlined for scalability and performance. It is ideal for developers looking to jumpstart their Storage Browser project with pre-configured AWS services like Cognito and S3.

## Features

- **Authentication**: Setup with Amazon Cognito for secure user authentication with email login.   
   - More info on how to setup and configuration option: https://docs.amplify.aws/react/build-a-backend/auth/set-up-auth/
- **Storage**: Configured with multiple S3 buckets and granular access controls. The sample is configured with
  - Default storage bucket intended for the `primary-team` Cognito group
  - Secondary storage bucket intended for the `secondary-team` Cognito group
  - Separate `admin` paths in both buckets for elevated access.
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
│   └── backend.ts            # Main backend definition
├── src/
│   ├── App.tsx               # Main application component
│   └── main.tsx              # Application entry point
└── package.json              # Project dependencies
```

## Getting Started

### Installation

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


## Verifying bucket access by user type

To verify that different users access different buckets:

1. Create Cognito users in different groups (`primary-team`, `secondary-team`, and optionally `admin`).
2. Sign in as each user and open Storage Browser.
3. Confirm access behavior:
   - `primary-team` users can access `primary-team/*` in `myStorageBucket`.
   - `secondary-team` users can access `secondary-team/*` in `mySecondaryStorageBucket`.
   - `admin` users can access `admin/*` and `backup_admin/*`.
4. Attempt cross-bucket access and confirm it is denied by IAM policies generated from the storage rules.

## Deploying to AWS

For detailed instructions on deploying your application, refer to the [deployment section](https://docs.amplify.aws/react/start/quickstart/#deploy-a-fullstack-app-to-aws) of our documentation.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for more information.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.


_These sample applications are provided as a reference to help get started easily and are not supported by AWS Support._
