// Firebase Configuration
// Get from Firebase Console -> Project Settings -> General -> Your apps
// IMPORTANT: Replace these with your actual values from Firebase Console!

export const firebaseConfig = {
  apiKey: "YOUR_API_KEY", // Replace with actual API key from Firebase Console
  authDomain: "onborda.firebaseapp.com",
  projectId: "onborda",
  storageBucket: "onborda.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID", // Replace with actual sender ID
  appId: "YOUR_APP_ID" // Replace with actual app ID
};

// Backend API URL - Will be updated after deploying Cloud Run
export const API_URL = process.env.VITE_API_URL || "http://localhost:8080";
