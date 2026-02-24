import { PolicyStatement, Effect } from 'aws-cdk-lib/aws-iam';

/**
 * Add cross-account access permissions to the Cognito authenticated role
 * This allows users authenticated via Entra ID to assume roles in other AWS accounts
 */
export function addCrossAccountAccess(backend: any) {
  const authenticatedRole = backend.auth.resources.authenticatedUserIamRole;
  
  // Replace these account IDs and role names with your actual values
  const crossAccountRoles = [
    'arn:aws:iam::222222222222:role/AmplifyStorageCrossAccountRole', // Account B
    'arn:aws:iam::333333333333:role/AmplifyStorageCrossAccountRole', // Account C
  ];
  
  // Allow assuming roles in other accounts
  authenticatedRole.addToPrincipalPolicy(
    new PolicyStatement({
      effect: Effect.ALLOW,
      actions: ['sts:AssumeRole'],
      resources: crossAccountRoles,
    })
  );

  // Allow getting credentials from Cognito Identity Pool
  authenticatedRole.addToPrincipalPolicy(
    new PolicyStatement({
      effect: Effect.ALLOW,
      actions: [
        'cognito-identity:GetCredentialsForIdentity',
        'cognito-identity:GetId',
      ],
      resources: ['*'],
    })
  );

  console.log('✅ Cross-account access permissions added to authenticated role');
}
