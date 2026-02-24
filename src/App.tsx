import {
  createAmplifyAuthAdapter,
  createStorageBrowser,
} from '@aws-amplify/ui-react-storage/browser';
import '@aws-amplify/ui-react-storage/styles.css';
import '@aws-amplify/ui-react/styles.css';
import './App.css';

import config from '../amplify_outputs.json';
import { Amplify } from 'aws-amplify';
import { Authenticator, Button, View, Heading, useAuthenticator } from '@aws-amplify/ui-react';
import { signInWithRedirect } from 'aws-amplify/auth';
import { useEffect } from 'react';

Amplify.configure(config);

const { StorageBrowser } = createStorageBrowser({
  config: createAmplifyAuthAdapter(),
});

function LoginPage() {
  const { user } = useAuthenticator((context) => [context.user]);

  const handleEntraIDSignIn = async () => {
    try {
      await signInWithRedirect({ provider: 'EntraID' });
    } catch (error) {
      console.error('Error signing in with Entra ID:', error);
    }
  };

  useEffect(() => {
    // Log authentication state for debugging
    console.log('User state:', user);
  }, [user]);

  return (
    <View textAlign="center" padding="xxl">
      <Heading level={2}>Storage Browser</Heading>
      <View padding="large">
        <Button
          onClick={handleEntraIDSignIn}
          variation="primary"
          size="large"
          isFullWidth
        >
          Sign in with Entra ID (Microsoft)
        </Button>
      </View>
    </View>
  );
}

function App() {
  return (
    <Authenticator
      hideSignUp={true}
      components={{
        SignIn: {
          Header() {
            return (
              <View textAlign="center" padding="large">
                <Heading level={3}>Sign in to Storage Browser</Heading>
              </View>
            );
          },
          Footer() {
            return <LoginPage />;
          },
        },
      }}
    >
      {({ signOut, user }) => (
        <>
          <div className="header">
            <h1>{`Hello ${user?.signInDetails?.loginId || user?.username}`}</h1>
            <Button onClick={signOut}>Sign out</Button>
          </div>
          <StorageBrowser />
        </>
      )}
    </Authenticator>
  );
}

export default App;
