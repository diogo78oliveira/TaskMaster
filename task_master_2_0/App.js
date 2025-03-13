import React, { useEffect } from 'react';
import { LogBox, AppState } from 'react-native';
// ...existing code...

// Disable long timer warnings which can impact debugging
LogBox.ignoreLogs(['Setting a timer']);

const App = () => {
  useEffect(() => {
    // Clean up resources when app goes to background
    const subscription = AppState.addEventListener('change', nextAppState => {
      if (nextAppState === 'background') {
        // Release expensive resources
      }
    });

    return () => {
      subscription.remove();
    };
  }, []);

  // ...existing code...
};

export default App;
