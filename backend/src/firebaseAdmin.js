import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

// Initialize Firebase Admin SDK
// In production (Cloud Run), use service account credentials from environment variables
// In development, you can use a service account key file

const initializeFirebaseAdmin = () => {
  try {
    if (admin.apps.length === 0) {
      // Check if running on Cloud Run with env variables
      if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            // Replace escaped newlines in the private key
            privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
          })
        });
        console.log('✅ Firebase Admin initialized with environment variables');
      } else {
        // Development: use service account key file
        // Download from Firebase Console -> Project Settings -> Service Accounts
        admin.initializeApp({
          credential: admin.credential.applicationDefault()
        });
        console.log('✅ Firebase Admin initialized with application default credentials');
      }
    }
  } catch (error) {
    console.error('❌ Error initializing Firebase Admin:', error);
    throw error;
  }
};

initializeFirebaseAdmin();

// Export Firebase Admin services
export const auth = admin.auth();
export const db = admin.firestore();

export default admin;
