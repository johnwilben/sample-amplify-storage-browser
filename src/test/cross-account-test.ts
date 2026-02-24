import { getCrossAccountS3Client, listCrossAccountObjects, getUserPrefix } from '../utils/cross-account-storage';
import { crossAccountBuckets, getBucketConfig } from '../config/cross-account-storage';

/**
 * Test cross-account access to S3 buckets
 */
export async function testCrossAccountAccess() {
  console.log('🧪 Testing cross-account S3 access...');
  console.log('');

  const results = {
    accountB: false,
    accountC: false,
  };

  // Test Account B
  try {
    console.log('Testing Account B...');
    const configB = getBucketConfig('accountB');
    const responseB = await listCrossAccountObjects(configB, undefined, 10);
    
    console.log('✅ Account B access successful!');
    console.log(`   Bucket: ${configB.bucket}`);
    console.log(`   Objects found: ${responseB.Contents?.length || 0}`);
    results.accountB = true;
  } catch (error) {
    console.error('❌ Account B access failed:', error);
  }

  console.log('');

  // Test Account C
  try {
    console.log('Testing Account C...');
    const configC = getBucketConfig('accountC');
    const responseC = await listCrossAccountObjects(configC, undefined, 10);
    
    console.log('✅ Account C access successful!');
    console.log(`   Bucket: ${configC.bucket}`);
    console.log(`   Objects found: ${responseC.Contents?.length || 0}`);
    results.accountC = true;
  } catch (error) {
    console.error('❌ Account C access failed:', error);
  }

  console.log('');
  console.log('Test Results:');
  console.log(`  Account B: ${results.accountB ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  Account C: ${results.accountC ? '✅ PASS' : '❌ FAIL'}`);

  return results;
}

/**
 * Test user-specific path access
 */
export async function testUserSpecificAccess() {
  console.log('🧪 Testing user-specific path access...');
  console.log('');

  try {
    const userPrefix = await getUserPrefix();
    console.log(`User prefix: ${userPrefix}`);

    const configB = getBucketConfig('accountB');
    const response = await listCrossAccountObjects(configB, userPrefix, 10);

    console.log('✅ User-specific access successful!');
    console.log(`   Objects in user path: ${response.Contents?.length || 0}`);
    
    return true;
  } catch (error) {
    console.error('❌ User-specific access failed:', error);
    return false;
  }
}

/**
 * Run all tests
 */
export async function runAllTests() {
  console.log('');
  console.log('═══════════════════════════════════════════');
  console.log('  Cross-Account Storage Access Tests');
  console.log('═══════════════════════════════════════════');
  console.log('');

  await testCrossAccountAccess();
  console.log('');
  await testUserSpecificAccess();

  console.log('');
  console.log('═══════════════════════════════════════════');
  console.log('  Tests Complete');
  console.log('═══════════════════════════════════════════');
}
