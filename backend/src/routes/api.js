import express from 'express';
import { authenticateToken } from '../middleware/auth.js';
import { db } from '../firebaseAdmin.js';

const router = express.Router();

/**
 * Public endpoint - no authentication required
 */
router.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    message: 'Backend API is running',
    timestamp: new Date().toISOString()
  });
});

/**
 * Protected endpoint - requires authentication
 * Example of reading from Firestore
 */
router.get('/protected', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    
    // Example: Read user data from Firestore
    const userDoc = await db.collection('users').doc(userId).get();
    
    let userData = null;
    if (userDoc.exists) {
      userData = userDoc.data();
    } else {
      // Create user document if it doesn't exist
      userData = {
        email: req.user.email,
        createdAt: new Date().toISOString(),
        lastLogin: new Date().toISOString()
      };
      await db.collection('users').doc(userId).set(userData);
    }

    res.json({
      message: 'This is a protected endpoint',
      user: {
        uid: req.user.uid,
        email: req.user.email,
        emailVerified: req.user.emailVerified
      },
      data: userData
    });
  } catch (error) {
    console.error('❌ Error in protected endpoint:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

/**
 * Protected endpoint - create/update data
 */
router.post('/data', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { data } = req.body;

    if (!data) {
      return res.status(400).json({ 
        error: 'Bad request',
        message: 'Data field is required' 
      });
    }

    // Save data to Firestore
    const docRef = await db.collection('userdata').add({
      userId,
      data,
      createdAt: new Date().toISOString()
    });

    res.json({
      message: 'Data saved successfully',
      id: docRef.id
    });
  } catch (error) {
    console.error('❌ Error saving data:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

/**
 * Protected endpoint - get user's data
 */
router.get('/data', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.uid;

    // Query user's data from Firestore
    const snapshot = await db.collection('userdata')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(10)
      .get();

    const data = [];
    snapshot.forEach(doc => {
      data.push({
        id: doc.id,
        ...doc.data()
      });
    });

    res.json({
      message: 'Data retrieved successfully',
      count: data.length,
      data
    });
  } catch (error) {
    console.error('❌ Error retrieving data:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

export default router;
