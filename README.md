# 🚀 SaaS Scalable Application

A complete, production-ready SaaS application built with Firebase, Cloud Run, and Firestore. Designed to scale to thousands of users with minimal infrastructure management.

## 📋 Architecture Overview

```
┌─────────────────┐       ┌──────────────────┐       ┌─────────────────────┐
│  User Browser   │──────▶│ Firebase Hosting │──────▶│  Cloud Run Backend  │
│    (React)      │       │   (SPA + CDN)    │       │  (Node.js + API)    │
└─────────────────┘       └──────────────────┘       └──────────┬──────────┘
                                                                 │
                          ┌──────────────────┐                  │
                          │ Firebase Auth    │◀─────────────────┤
                          │ (Email/Social)   │                  │
                          └──────────────────┘                  │
                                                                 │
                          ┌──────────────────┐                  │
                          │   Firestore DB   │◀─────────────────┘
                          │  (NoSQL Cloud)   │
                          └──────────────────┘
```

## 🎯 Key Features

- **Frontend**: React SPA with Vite
- **Backend**: Node.js Express API on Cloud Run
- **Authentication**: Firebase Authentication (Email/Password, Social Login)
- **Database**: Cloud Firestore (Serverless, Scalable)
- **Hosting**: Firebase Hosting with global CDN
- **CI/CD**: GitHub Actions for automated deployment
- **Scalability**: Auto-scaling from 0 to thousands of users

## 📁 Project Structure

```
.
├── frontend/                 # React Frontend
│   ├── src/
│   │   ├── App.jsx          # Main application component
│   │   ├── firebase.js      # Firebase SDK initialization
│   │   └── firebaseConfig.js # Firebase configuration
│   ├── package.json
│   ├── vite.config.js
│   ├── firebase.json        # Firebase Hosting config
│   └── .firebaserc          # Firebase project link
│
├── backend/                  # Node.js Backend
│   ├── src/
│   │   ├── server.js        # Express server
│   │   ├── firebaseAdmin.js # Firebase Admin SDK
│   │   ├── middleware/
│   │   │   └── auth.js      # JWT verification middleware
│   │   └── routes/
│   │       └── api.js       # API endpoints
│   ├── Dockerfile           # Container configuration
│   ├── package.json
│   └── .env.example         # Environment variables template
│
└── .github/
    └── workflows/
        ├── deploy-frontend.yml  # Frontend deployment
        └── deploy-backend.yml   # Backend deployment
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Firebase CLI (`npm install -g firebase-tools`)
- Google Cloud CLI (`gcloud`)
- Firebase Project created
- Google Cloud Project with billing enabled

### 1️⃣ Setup Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable **Firebase Hosting**
4. Enable **Firebase Authentication** (Email/Password)
5. Create **Firestore Database** (Production mode)
6. Get your Firebase config from Project Settings

### 2️⃣ Setup Google Cloud

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable **Cloud Run API**
3. Enable **Container Registry API**
4. Create a service account for Firebase Admin SDK:
   - Go to IAM & Admin → Service Accounts
   - Create service account with "Firebase Admin SDK" role
   - Generate JSON key

### 3️⃣ Configure Frontend

1. Update `frontend/.firebaserc`:
```json
{
  "projects": {
    "default": "your-project-id"
  }
}
```

2. Update `frontend/src/firebaseConfig.js` with your Firebase config

3. Install dependencies:
```bash
cd frontend
npm install
```

### 4️⃣ Configure Backend

1. Copy environment variables:
```bash
cd backend
cp .env.example .env
```

2. Update `.env` with your credentials:
   - Firebase Project ID
   - Firebase Service Account credentials
   - Allowed CORS origins

3. Install dependencies:
```bash
npm install
```

### 5️⃣ Local Development

**Frontend:**
```bash
cd frontend
npm run dev
# Opens on http://localhost:3000
```

**Backend:**
```bash
cd backend
npm run dev
# Runs on http://localhost:8080
```

## 📦 Deployment

### Option 1: Manual Deployment

#### Deploy Frontend
```bash
cd frontend
npm run build
firebase login
firebase deploy
```

#### Deploy Backend
```bash
cd backend

# Build and push Docker image
gcloud builds submit --tag gcr.io/PROJECT_ID/saas-backend

# Deploy to Cloud Run
gcloud run deploy saas-backend \
  --image gcr.io/PROJECT_ID/saas-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars="FIREBASE_PROJECT_ID=your-project-id" \
  --set-env-vars="FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com" \
  --set-env-vars="FIREBASE_PRIVATE_KEY=your-private-key"
```

### Option 2: Automated Deployment (GitHub Actions)

1. **Setup GitHub Secrets:**

Go to your repository Settings → Secrets and variables → Actions, and add:

**Frontend Secrets:**
- `FIREBASE_SERVICE_ACCOUNT` - Firebase service account JSON
- `FIREBASE_PROJECT_ID` - Your Firebase project ID
- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_STORAGE_BUCKET`
- `VITE_FIREBASE_MESSAGING_SENDER_ID`
- `VITE_FIREBASE_APP_ID`
- `VITE_API_URL` - Your Cloud Run service URL

**Backend Secrets:**
- `GCP_PROJECT_ID` - Google Cloud project ID
- `GCP_WORKLOAD_IDENTITY_PROVIDER` - Workload identity provider
- `GCP_SERVICE_ACCOUNT` - Service account email
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `ALLOWED_ORIGINS` - Comma-separated allowed origins

2. **Push to GitHub:**
```bash
git push origin main
```

GitHub Actions will automatically deploy both frontend and backend! 🎉

## 🔒 Security Best Practices

1. **Never commit `.env` files** - Always use `.env.example`
2. **Use GitHub Secrets** for sensitive data
3. **Enable Firestore Security Rules**
4. **Configure CORS** properly in backend
5. **Use HTTPS only** (Firebase Hosting does this automatically)

## 📊 Firestore Security Rules

Add these rules in Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // User data collection
    match /userdata/{document} {
      allow read, write: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
    }
  }
}
```

## 🧪 Testing

### Test Frontend Locally
```bash
cd frontend
npm run dev
```

### Test Backend Locally
```bash
cd backend
npm run dev
```

### Test Backend API
```bash
# Health check
curl http://localhost:8080/api/health

# Protected endpoint (requires token)
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8080/api/protected
```

## 📈 Scaling Considerations

This architecture is designed to scale automatically:

- **Frontend**: Firebase Hosting uses global CDN, handles millions of requests
- **Backend**: Cloud Run auto-scales from 0 to 1000+ instances
- **Database**: Firestore is serverless and scales automatically
- **Auth**: Firebase Auth handles thousands of concurrent users

### Performance Tips

1. Enable Cloud Run **min-instances** (1-2) for production to reduce cold starts
2. Use Firestore **indexes** for complex queries
3. Implement **caching** in backend for frequently accessed data
4. Use **Firebase Performance Monitoring** to track frontend performance

## 🛠️ Troubleshooting

### Frontend Issues

**Issue**: Build fails
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
npm run build
```

**Issue**: Firebase config not found
- Check `firebaseConfig.js` has correct values
- Verify `.firebaserc` has correct project ID

### Backend Issues

**Issue**: Authentication fails
- Verify Firebase Admin credentials in `.env`
- Check private key has proper line breaks (`\n`)

**Issue**: CORS errors
- Add frontend URL to `ALLOWED_ORIGINS` in `.env`
- Redeploy backend

**Issue**: Cloud Run deployment fails
- Check GCP billing is enabled
- Verify Container Registry API is enabled
- Check service account permissions

## 📚 API Documentation

### Public Endpoints

#### `GET /api/health`
Health check endpoint

**Response:**
```json
{
  "status": "healthy",
  "message": "Backend API is running",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Protected Endpoints (Require Authentication)

#### `GET /api/protected`
Get user data

**Headers:**
```
Authorization: Bearer <firebase-jwt-token>
```

**Response:**
```json
{
  "message": "This is a protected endpoint",
  "user": {
    "uid": "user-id",
    "email": "user@example.com",
    "emailVerified": true
  },
  "data": { ... }
}
```

#### `POST /api/data`
Create user data

**Headers:**
```
Authorization: Bearer <firebase-jwt-token>
```

**Body:**
```json
{
  "data": "any data here"
}
```

#### `GET /api/data`
Get user's data

**Headers:**
```
Authorization: Bearer <firebase-jwt-token>
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - feel free to use this for your projects!

## 🆘 Support

For issues and questions:
- Check the troubleshooting section above
- Review Firebase and Cloud Run documentation
- Open an issue on GitHub

## 🎓 Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [React Documentation](https://react.dev/)
- [Express.js Documentation](https://expressjs.com/)

---

Built with ❤️ for scalable SaaS applications
