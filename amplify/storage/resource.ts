import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
  name: 'myStorageBucket',
  isDefault: true,
  access: (allow) => ({
    'public/*': [allow.guest.to(['read'])],
    'primary-team/*': [allow.groups(['primary-team']).to(['read', 'write', 'delete'])],
    'admin/*': [allow.groups(['admin']).to(['read', 'write', 'delete'])],
  }),
});

export const secondaryStorage = defineStorage({
  name: 'mySecondaryStorageBucket',
  access: (allow) => ({
    'backup_public/*': [allow.guest.to(['read'])],
    'secondary-team/*': [allow.groups(['secondary-team']).to(['read', 'write', 'delete'])],
    'backup_admin/*': [allow.groups(['admin']).to(['read', 'write', 'delete'])],
  }),
});
