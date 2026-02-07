import { defineBackend } from "@aws-amplify/backend";
import { auth } from "./auth/resource";
import { Policy, PolicyStatement, Effect } from "aws-cdk-lib/aws-iam";

/**
 * @see https://docs.amplify.aws/react/build-a-backend/ to add storage, functions, and more
 */
const backend = defineBackend({
  auth,
});

/**
 * Note: This code assumes the existence of one or more S3 buckets.
 * Add the names of all buckets you want this app to manage below.
 * Ensure the buckets already exist in your AWS account.
 */
const bucketNames = [
  "palawanpay-test-app-1769841477",
  // Add additional bucket names here, e.g. "my-other-bucket-name",
];

backend.addOutput({
  version: "1.3",
  storage: {
    aws_region: "ap-southeast-1",
    bucket_name: bucketNames[0],
    buckets: bucketNames.map((bucketName) => ({
      name: bucketName,
      bucket_name: bucketName,
      aws_region: "us-east-1",
      paths: {
        "*": {
          authenticated: ["get", "list", "write", "delete"],
        },
      },
    })),
  },
});

/**
 * Define an inline policy to attach to Amplify's un-auth role
 * This policy defines how unauthenticated users can access your existing bucket
 */
const unauthPolicy = new Policy(backend.stack, "customBucketUnauthPolicy", {
  statements: [
    new PolicyStatement({
      effect: Effect.DENY,
      actions: ["s3:*"],
      resources: ["*"],
    }),
  ],
});

/**
 * Define an inline policy to attach to the admin group role
 * This policy defines how admin users can access your existing bucket
 */
const adminPolicy = new Policy(backend.stack, "customBucketAdminPolicy", {
  statements: [
    new PolicyStatement({
      effect: Effect.ALLOW,
      actions: ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      resources: bucketNames.map((bucketName) => `arn:aws:s3:::${bucketName}/*`),
    }),
    new PolicyStatement({
      effect: Effect.ALLOW,
      actions: ["s3:ListBucket"],
      resources: bucketNames.map((bucketName) => `arn:aws:s3:::${bucketName}`),
    }),
  ],
});

/**
 * Define an inline policy to attach to the ReadOnly group role
 * This policy allows read-only access to your existing bucket
 */
const readOnlyPolicy = new Policy(backend.stack, "customBucketReadOnlyPolicy", {
  statements: [
    new PolicyStatement({
      effect: Effect.ALLOW,
      actions: ["s3:GetObject"],
      resources: bucketNames.map((bucketName) => `arn:aws:s3:::${bucketName}/*`),
    }),
    new PolicyStatement({
      effect: Effect.ALLOW,
      actions: ["s3:ListBucket"],
      resources: bucketNames.map((bucketName) => `arn:aws:s3:::${bucketName}`),
    }),
  ],
});

// Add the policies to the unauthenticated user role
backend.auth.resources.unauthenticatedUserIamRole.attachInlinePolicy(
  unauthPolicy
);

// Add the policies to the authenticated, admin, and ReadOnly roles
// - All authenticated users get read-only access
// - Admin group users get full read/write/delete access
backend.auth.resources.authenticatedUserIamRole.attachInlinePolicy(readOnlyPolicy);
backend.auth.resources.groups["admin"].role.attachInlinePolicy(adminPolicy);
backend.auth.resources.groups["ReadOnly"].role.attachInlinePolicy(readOnlyPolicy);
