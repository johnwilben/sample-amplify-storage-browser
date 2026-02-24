import { fetchAuthSession } from 'aws-amplify/auth';
import { STSClient, AssumeRoleCommand } from '@aws-sdk/client-sts';
import { S3Client, ListObjectsV2Command, GetObjectCommand, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import type { CrossAccountBucketConfig } from '../config/cross-account-storage';

/**
 * Get an S3 client with cross-account access by assuming a role
 */
export async function getCrossAccountS3Client(
  roleArn: string,
  region: string
): Promise<S3Client> {
  try {
    // Get current Cognito credentials
    const session = await fetchAuthSession();
    
    if (!session.credentials) {
      throw new Error('No credentials available. Please sign in.');
    }

    // Create STS client with Cognito credentials
    const stsClient = new STSClient({
      region,
      credentials: session.credentials,
    });

    // Assume the cross-account role
    const assumeRoleCommand = new AssumeRoleCommand({
      RoleArn: roleArn,
      RoleSessionName: `amplify-storage-${Date.now()}`,
      DurationSeconds: 3600, // 1 hour
    });

    const assumedRole = await stsClient.send(assumeRoleCommand);

    if (!assumedRole.Credentials) {
      throw new Error('Failed to assume role. No credentials returned.');
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
  } catch (error) {
    console.error('Error getting cross-account S3 client:', error);
    throw error;
  }
}

/**
 * List objects in a cross-account S3 bucket
 */
export async function listCrossAccountObjects(
  config: CrossAccountBucketConfig,
  prefix?: string,
  maxKeys: number = 100
) {
  const s3Client = await getCrossAccountS3Client(config.roleArn, config.region);
  
  const command = new ListObjectsV2Command({
    Bucket: config.bucket,
    Prefix: prefix,
    MaxKeys: maxKeys,
  });

  return await s3Client.send(command);
}

/**
 * Get an object from a cross-account S3 bucket
 */
export async function getCrossAccountObject(
  config: CrossAccountBucketConfig,
  key: string
) {
  const s3Client = await getCrossAccountS3Client(config.roleArn, config.region);
  
  const command = new GetObjectCommand({
    Bucket: config.bucket,
    Key: key,
  });

  return await s3Client.send(command);
}

/**
 * Upload an object to a cross-account S3 bucket
 */
export async function putCrossAccountObject(
  config: CrossAccountBucketConfig,
  key: string,
  body: any,
  contentType?: string
) {
  const s3Client = await getCrossAccountS3Client(config.roleArn, config.region);
  
  const command = new PutObjectCommand({
    Bucket: config.bucket,
    Key: key,
    Body: body,
    ContentType: contentType,
    ServerSideEncryption: 'AES256', // Enforce encryption
  });

  return await s3Client.send(command);
}

/**
 * Delete an object from a cross-account S3 bucket
 */
export async function deleteCrossAccountObject(
  config: CrossAccountBucketConfig,
  key: string
) {
  const s3Client = await getCrossAccountS3Client(config.roleArn, config.region);
  
  const command = new DeleteObjectCommand({
    Bucket: config.bucket,
    Key: key,
  });

  return await s3Client.send(command);
}

/**
 * Get user-specific path prefix based on Cognito identity
 */
export async function getUserPrefix(): Promise<string> {
  const session = await fetchAuthSession();
  const identityId = session.identityId;
  
  if (!identityId) {
    throw new Error('No identity ID available');
  }
  
  return `private/${identityId}/`;
}
