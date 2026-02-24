import { defineAuth } from '@aws-amplify/backend';

/**
 * Define and configure your auth resource
 * @see https://docs.amplify.aws/gen2/build-a-backend/auth
 */
export const auth = defineAuth({
  loginWith: {
    email: true,
    externalProviders: {
      saml: {
        name: 'EntraID',
        metadata: {
          metadataType: 'URL',
          metadataContent: 'https://login.microsoftonline.com/84955449-af74-4a26-a735-f573b47d98ba/federationmetadata/2007-06/federationmetadata.xml'
        }
      },
      callbackUrls: [
        'http://localhost:5173',
        'http://localhost:5173/auth/callback'
      ],
      logoutUrls: [
        'http://localhost:5173',
        'http://localhost:5173/auth/logout'
      ]
    }
  },
  groups: ['admin']
});
