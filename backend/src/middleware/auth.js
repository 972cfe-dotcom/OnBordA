import { auth } from '../firebaseAdmin.js';

/**
 * Middleware to verify Firebase JWT token
 * Extracts token from Authorization header and verifies it
 * Adds decoded token to request object as req.user
 */
export const authenticateToken = async (req, res, next) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        error: 'Unauthorized',
        message: 'No token provided or invalid format. Expected: Bearer <token>' 
      });
    }

    // Extract token (remove "Bearer " prefix)
    const token = authHeader.substring(7);

    // Verify token with Firebase Admin
    const decodedToken = await auth.verifyIdToken(token);
    
    // Add user info to request object
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      ...decodedToken
    };

    next();
  } catch (error) {
    console.error('❌ Token verification error:', error);
    
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({ 
        error: 'Token expired',
        message: 'Your session has expired. Please sign in again.' 
      });
    }
    
    return res.status(401).json({ 
      error: 'Unauthorized',
      message: 'Invalid token' 
    });
  }
};
