import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { storage, secondaryStorage } from './storage/resource';
import { addCrossAccountAccess } from './backend/custom-resources';

/**
 * @see https://docs.amplify.aws/react/build-a-backend/ to add storage, functions, and more
 */
const backend = defineBackend({
  auth,
  storage, 
  secondaryStorage
});

// Add cross-account access permissions
// Uncomment this after setting up cross-account roles in other accounts
// addCrossAccountAccess(backend);
