# 📦 Deployment Guide

This guide provides step-by-step instructions for deploying your SaaS application to Firebase and Google Cloud.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Frontend Deployment](#frontend-deployment)
- [Backend Deployment](#backend-deployment)
- [Environment Variables](#environment-variables)
- [GitHub Actions Setup](#github-actions-setup)
- [Post-Deployment](#post-deployment)

## Prerequisites

### Required Tools

1. **Node.js 18+**
   ```bash
   node --version
   ```

2. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase --version
   ```

3. **Google Cloud CLI**
   ```bash
   # Install from: https://cloud.google.com/sdk/docs/install
   gcloud --version
   ```

4. **Git**
   ```bash
   git --version
   ```

### Required Accounts

- Google Account
- Firebase Project (with billing enabled for Firestore)
- Google Cloud Project (with billing enabled for Cloud Run)

## Initial Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "my-saas-app")
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Enable Firebase Services

**Authentication:**
1. Go to Authentication → Get Started
2. Enable "Email/Password" sign-in method
3. (Optional) Enable other providers (Google, GitHub, etc.)

**Firestore:**
1. Go to Firestore Database → Create Database
2. Choose "Production mode"
3. Select a location (e.g., us-central1)
4. Click "Enable"

**Hosting:**
1. Go to Hosting → Get Started
2. Follow the setup wizard

### 3. Setup Google Cloud

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project (it's automatically created in GCP)
3. Enable billing (required for Cloud Run)

**Enable APIs:**
```bash
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### 4. Create Service Account

For Firebase Admin SDK (backend):

```bash
# Go to IAM & Admin → Service Accounts
# Or use CLI:
gcloud iam service-accounts create firebase-admin-sa \
  --display-name="Firebase Admin Service Account"

# Grant Firebase Admin role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:firebase-admin-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/firebase.admin"

# Create and download key
gcloud iam service-accounts keys create firebase-admin-key.json \
  --iam-account=firebase-admin-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

⚠️ **Security Note:** Never commit the JSON key file to Git!

## Frontend Deployment

### Step 1: Configure Firebase

1. **Update `.firebaserc`:**
   ```json
   {
     "projects": {
       "default": "your-project-id"
     }
   }
   ```

2. **Get Firebase Configuration:**
   - Go to Firebase Console → Project Settings
   - Scroll to "Your apps" section
   - Click "Add app" → Web (</>) icon
   - Register app and copy the config

3. **Update `frontend/src/firebaseConfig.js`:**
   ```javascript
   export const firebaseConfig = {
     apiKey: "AIza...",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abc..."
   };
   ```

### Step 2: Build and Deploy

```bash
cd frontend

# Install dependencies
npm install

# Build the app
npm run build

# Login to Firebase (first time only)
firebase login

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

✅ **Success!** Your frontend is now live at `https://your-project-id.web.app`

## Backend Deployment

### Step 1: Configure Environment

1. **Copy environment template:**
   ```bash
   cd backend
   cp .env.example .env
   ```

2. **Update `.env` file:**
   ```env
   NODE_ENV=production
   PORT=8080
   
   # From firebase-admin-key.json
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_CLIENT_EMAIL=firebase-admin-sa@your-project-id.iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY_HERE\n-----END PRIVATE KEY-----\n"
   
   # Your frontend URLs
   ALLOWED_ORIGINS=https://your-project-id.web.app,https://your-project-id.firebaseapp.com
   ```

### Step 2: Test Locally

```bash
cd backend

# Install dependencies
npm install

# Run locally
npm run dev

# Test the API
curl http://localhost:8080/api/health
```

### Step 3: Deploy to Cloud Run

**Option A: Using gcloud CLI**

```bash
cd backend

# Authenticate
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Build Docker image
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/saas-backend

# Deploy to Cloud Run
gcloud run deploy saas-backend \
  --image gcr.io/YOUR_PROJECT_ID/saas-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars="NODE_ENV=production,FIREBASE_PROJECT_ID=YOUR_PROJECT_ID,FIREBASE_CLIENT_EMAIL=firebase-admin-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com,FIREBASE_PRIVATE_KEY=$(cat firebase-admin-key.json | jq -r '.private_key'),ALLOWED_ORIGINS=https://YOUR_PROJECT_ID.web.app" \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10
```

**Option B: Using Cloud Console**

1. Go to Cloud Run in GCP Console
2. Click "Create Service"
3. Select "Deploy from Cloud Registry"
4. Build and push your image first:
   ```bash
   gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/saas-backend
   ```
5. Fill in service details
6. Add environment variables
7. Click "Create"

✅ **Success!** Your backend is now live at `https://saas-backend-xxx.run.app`

### Step 4: Update Frontend with Backend URL

1. Update `frontend/src/firebaseConfig.js`:
   ```javascript
   export const API_URL = "https://saas-backend-xxx.run.app";
   ```

2. Redeploy frontend:
   ```bash
   cd frontend
   npm run build
   firebase deploy --only hosting
   ```

## Environment Variables

### Frontend Environment Variables (GitHub Secrets)

```
VITE_FIREBASE_API_KEY=AIza...
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789
VITE_FIREBASE_APP_ID=1:123456789:web:abc...
VITE_API_URL=https://saas-backend-xxx.run.app
FIREBASE_SERVICE_ACCOUNT=<entire firebase-admin-key.json content>
FIREBASE_PROJECT_ID=your-project-id
```

### Backend Environment Variables (GitHub Secrets)

```
GCP_PROJECT_ID=your-project-id
GCP_WORKLOAD_IDENTITY_PROVIDER=projects/123456789/locations/global/workloadIdentityPools/...
GCP_SERVICE_ACCOUNT=firebase-admin-sa@your-project-id.iam.gserviceaccount.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-admin-sa@your-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
ALLOWED_ORIGINS=https://your-project-id.web.app,https://your-project-id.firebaseapp.com
```

## GitHub Actions Setup

### Step 1: Setup Workload Identity Federation (Recommended)

This is more secure than using service account keys.

```bash
# Create workload identity pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="YOUR_PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create workload identity provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="YOUR_PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Get the provider name
gcloud iam workload-identity-pools providers describe "github-provider" \
  --project="YOUR_PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --format="value(name)"
```

### Step 2: Configure GitHub Secrets

1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add all the secrets listed in [Environment Variables](#environment-variables)

### Step 3: Enable GitHub Actions

1. Push your code to GitHub
2. Go to Actions tab
3. Workflows will run automatically on push to main branch

## Post-Deployment

### 1. Configure Firestore Security Rules

Go to Firestore → Rules and update:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /userdata/{document} {
      allow read: if request.auth != null && 
                     resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               resource.data.userId == request.auth.uid;
    }
  }
}
```

### 2. Test the Deployment

1. **Open your frontend URL**
   ```
   https://your-project-id.web.app
   ```

2. **Sign up with email/password**

3. **Test protected API call**
   - Click "Call Protected API" button
   - Should see your user data

4. **Check backend health**
   ```bash
   curl https://saas-backend-xxx.run.app/api/health
   ```

### 3. Monitor Your Application

**Firebase Console:**
- Authentication → Users (see registered users)
- Firestore → Data (see database records)
- Hosting → Dashboard (see hosting metrics)

**Google Cloud Console:**
- Cloud Run → saas-backend → Metrics (see API usage)
- Logs Explorer (see application logs)

### 4. Setup Monitoring and Alerts

```bash
# Enable Cloud Monitoring
gcloud services enable monitoring.googleapis.com

# Create uptime check for backend
gcloud monitoring uptime-checks create https://saas-backend-xxx.run.app/api/health \
  --display-name="Backend Health Check"
```

## Troubleshooting

### Frontend Deployment Issues

**Issue:** `firebase deploy` fails
```bash
# Re-authenticate
firebase logout
firebase login

# Check project
firebase projects:list
firebase use YOUR_PROJECT_ID
```

**Issue:** Build fails
```bash
# Clear cache
rm -rf node_modules package-lock.json dist
npm install
npm run build
```

### Backend Deployment Issues

**Issue:** Cloud Run deployment fails
```bash
# Check project
gcloud config get-value project

# Check APIs are enabled
gcloud services list --enabled

# View build logs
gcloud builds list
gcloud builds log BUILD_ID
```

**Issue:** Authentication errors
- Verify `FIREBASE_PRIVATE_KEY` has proper `\n` characters
- Check service account has Firebase Admin role
- Ensure project ID matches everywhere

**Issue:** CORS errors
- Verify `ALLOWED_ORIGINS` includes your frontend URL
- Check frontend is using correct backend URL
- Redeploy backend after changes

### GitHub Actions Issues

**Issue:** Workflow fails
- Check all secrets are set correctly
- Verify service account permissions
- Check workflow YAML syntax
- View workflow logs in Actions tab

## Best Practices

1. **Use environment-specific configs:**
   - Development: `.env.local`
   - Staging: `.env.staging`
   - Production: `.env.production`

2. **Never commit secrets:**
   - Always use `.gitignore`
   - Use GitHub Secrets for CI/CD
   - Use Secret Manager for sensitive data

3. **Monitor costs:**
   - Set up billing alerts in GCP
   - Use Cloud Run min/max instances wisely
   - Monitor Firestore read/write operations

4. **Implement proper logging:**
   - Use structured logging
   - Send logs to Cloud Logging
   - Set up error tracking (e.g., Sentry)

5. **Regular backups:**
   - Enable Firestore automatic backups
   - Export critical data regularly

## Next Steps

- [ ] Setup custom domain for frontend
- [ ] Configure Cloud Run custom domain
- [ ] Enable Cloud CDN for backend
- [ ] Setup monitoring and alerts
- [ ] Implement rate limiting
- [ ] Add email verification
- [ ] Setup staging environment
- [ ] Configure Cloud Armor for DDoS protection

---

For more help, see the [main README](./README.md) or open an issue.
