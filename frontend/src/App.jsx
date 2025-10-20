import { useState, useEffect } from 'react';
import { auth } from './firebase';
import { onAuthStateChanged, signInWithEmailAndPassword, signOut, createUserWithEmailAndPassword } from 'firebase/auth';
import axios from 'axios';
import { API_URL } from './firebaseConfig';
import './App.css';

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [apiResponse, setApiResponse] = useState(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleSignUp = async (e) => {
    e.preventDefault();
    setError('');
    try {
      await createUserWithEmailAndPassword(auth, email, password);
      setEmail('');
      setPassword('');
    } catch (err) {
      setError(err.message);
    }
  };

  const handleSignIn = async (e) => {
    e.preventDefault();
    setError('');
    try {
      await signInWithEmailAndPassword(auth, email, password);
      setEmail('');
      setPassword('');
    } catch (err) {
      setError(err.message);
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut(auth);
      setApiResponse(null);
    } catch (err) {
      setError(err.message);
    }
  };

  const callProtectedAPI = async () => {
    try {
      const token = await user.getIdToken();
      const response = await axios.get(`${API_URL}/api/protected`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      setApiResponse(response.data);
    } catch (err) {
      setError(err.response?.data?.error || err.message);
    }
  };

  if (loading) {
    return <div className="container">Loading...</div>;
  }

  return (
    <div className="container">
      <h1>🚀 SaaS Application</h1>
      <p className="subtitle">Firebase + Cloud Run + Firestore</p>
      
      {!user ? (
        <div className="auth-container">
          <h2>Sign In / Sign Up</h2>
          {error && <div className="error">{error}</div>}
          
          <form className="auth-form">
            <input
              type="email"
              placeholder="Email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
            <input
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
            <div className="button-group">
              <button type="submit" onClick={handleSignIn}>Sign In</button>
              <button type="button" onClick={handleSignUp} className="secondary">Sign Up</button>
            </div>
          </form>
        </div>
      ) : (
        <div className="user-container">
          <h2>Welcome!</h2>
          <p>Email: <strong>{user.email}</strong></p>
          <p>UID: <code>{user.uid}</code></p>
          
          <div className="button-group">
            <button onClick={callProtectedAPI}>Call Protected API</button>
            <button onClick={handleSignOut} className="secondary">Sign Out</button>
          </div>

          {apiResponse && (
            <div className="api-response">
              <h3>API Response:</h3>
              <pre>{JSON.stringify(apiResponse, null, 2)}</pre>
            </div>
          )}

          {error && <div className="error">{error}</div>}
        </div>
      )}
    </div>
  );
}

export default App;
