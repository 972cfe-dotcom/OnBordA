// Firebase Configuration
// Replace these values with your actual Firebase project configuration
// You can find these in Firebase Console -> Project Settings -> General -> Your apps

export const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
};

// Backend API URL - Update this after deploying your Cloud Run service
export const API_URL = process.env.VITE_API_URL || "https://YOUR_CLOUD_RUN_URL";
