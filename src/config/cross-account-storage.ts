/**
 * Cross-account S3 bucket configuration
 * Replace these values with your actual bucket names, regions, and role ARNs
 */

export interface CrossAccountBucketConfig {
  bucket: string;
  region: string;
  roleArn: string;
  accountId: string;
}

export const crossAccountBuckets: Record<string, CrossAccountBucketConfig> = {
  accountB: {
    bucket: 'your-bucket-name-account-b',
    region: 'ap-southeast-1',
    roleArn: 'arn:aws:iam::222222222222:role/AmplifyStorageCrossAccountRole',
    accountId: '222222222222',
  },
  accountC: {
    bucket: 'your-bucket-name-account-c',
    region: 'ap-southeast-1',
    roleArn: 'arn:aws:iam::333333333333:role/AmplifyStorageCrossAccountRole',
    accountId: '333333333333',
  },
};

/**
 * Get bucket configuration by account key
 */
export function getBucketConfig(accountKey: string): CrossAccountBucketConfig {
  const config = crossAccountBuckets[accountKey];
  if (!config) {
    throw new Error(`No bucket configuration found for account: ${accountKey}`);
  }
  return config;
}

/**
 * Get all configured bucket accounts
 */
export function getAllBucketAccounts(): string[] {
  return Object.keys(crossAccountBuckets);
}
