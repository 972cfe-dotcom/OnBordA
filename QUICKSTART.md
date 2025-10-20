# ⚡ Quick Start Guide

Get your SaaS application running in under 10 minutes!

## 🎯 Prerequisites

- Node.js 18+ installed
- Google account
- Terminal/Command line access

## 📝 Setup Steps

### 1️⃣ Create Firebase Project (2 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "**Add project**"
3. Enter project name: `my-saas-app`
4. Click "**Continue**" → "**Continue**" → "**Create project**"
5. Wait for project creation
6. Click "**Continue**"

### 2️⃣ Enable Firebase Services (3 minutes)

**Enable Authentication:**
1. Left sidebar → Click "**Authentication**"
2. Click "**Get started**"
3. Click "**Email/Password**" → Toggle **Enable** → Click "**Save**"

**Enable Firestore:**
1. Left sidebar → Click "**Firestore Database**"
2. Click "**Create database**"
3. Select "**Start in production mode**" → Click "**Next**"
4. Choose a location (e.g., `us-central1`) → Click "**Enable**"

**Get Firebase Config:**
1. Click the ⚙️ gear icon → "**Project settings**"
2. Scroll to "**Your apps**" section
3. Click the `</>` (Web) icon
4. Enter app nickname: `my-saas-frontend`
5. Click "**Register app**"
6. **Copy the firebaseConfig object** - you'll need this!

```javascript
// Copy this entire config object
const firebaseConfig = {
  apiKey: "AIzaSy...",
  authDomain: "my-saas-app.firebaseapp.com",
  projectId: "my-saas-app",
  storageBucket: "my-saas-app.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc..."
};
```

### 3️⃣ Setup Local Development (2 minutes)

**Clone and Install:**
```bash
# Clone the repository
cd /path/to/your/projects
git clone https://github.com/yourusername/your-repo.git
cd your-repo

# Install frontend dependencies
cd frontend
npm install

# Install backend dependencies
cd ../backend
npm install
cd ..
```

### 4️⃣ Configure Frontend (1 minute)

Edit `frontend/src/firebaseConfig.js`:

```javascript
// Replace with YOUR Firebase config from step 2
export const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
};

// For now, use localhost backend
export const API_URL = "http://localhost:8080";
```

### 5️⃣ Configure Backend (1 minute)

Create `backend/.env` file:

```bash
cd backend
cp .env.example .env
```

Edit `backend/.env`:

```env
NODE_ENV=development
PORT=8080

# Use your Firebase project ID
FIREBASE_PROJECT_ID=my-saas-app

# For local development, these can be empty
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

# Allow frontend to connect
ALLOWED_ORIGINS=http://localhost:3000
```

### 6️⃣ Run the Application (1 minute)

**Terminal 1 - Backend:**
```bash
cd backend
npm run dev
```

You should see:
```
╔═══════════════════════════════════════╗
║   🚀 SaaS Backend Server Started     ║
╚═══════════════════════════════════════╝
  
  Port: 8080
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm run dev
```

You should see:
```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:3000/
  ➜  Network: use --host to expose
```

### 7️⃣ Test the Application! 🎉

1. Open browser: `http://localhost:3000`
2. You should see the login screen
3. Click "**Sign Up**"
4. Enter email: `test@example.com`
5. Enter password: `password123`
6. Click "**Sign Up**"
7. You should now be logged in!
8. Click "**Call Protected API**" to test backend connection

## ✅ Success!

Your SaaS application is now running locally! 🎊

## 🚀 Next Steps

### Make It Your Own

1. **Change the app name:**
   - Edit `frontend/index.html` (title)
   - Edit `frontend/src/App.jsx` (heading)

2. **Customize the design:**
   - Edit `frontend/src/App.css`
   - Change colors, fonts, layout

3. **Add your features:**
   - Edit `backend/src/routes/api.js` (backend logic)
   - Edit `frontend/src/App.jsx` (frontend UI)

### Deploy to Production

When ready to deploy, follow the [Deployment Guide](./DEPLOYMENT.md).

## 🐛 Troubleshooting

### Frontend won't start

```bash
# Clear and reinstall
cd frontend
rm -rf node_modules package-lock.json
npm install
npm run dev
```

### Backend won't start

```bash
# Check Node version (must be 18+)
node --version

# Reinstall dependencies
cd backend
rm -rf node_modules package-lock.json
npm install
npm run dev
```

### Can't sign up users

1. Check Firebase Authentication is enabled
2. Verify `firebaseConfig` is correct in `frontend/src/firebaseConfig.js`
3. Check browser console for errors (F12 → Console tab)

### Backend API calls fail

1. Check backend is running on port 8080
2. Verify `API_URL` in `frontend/src/firebaseConfig.js` is `http://localhost:8080`
3. Check CORS is configured in `backend/.env`

### "Permission denied" in Firestore

1. Go to Firebase Console → Firestore Database
2. Click "**Rules**" tab
3. Change to:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
4. Click "**Publish**"

## 📚 Learn More

- **Full Documentation:** [README.md](./README.md)
- **Architecture Details:** [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Deployment Guide:** [DEPLOYMENT.md](./DEPLOYMENT.md)

## 💡 Tips

1. **Hot Reload:** Both frontend and backend support hot reload - changes are reflected automatically
2. **DevTools:** Press F12 in browser to see console logs and network requests
3. **Backend Logs:** Watch the terminal where backend is running for API logs
4. **Firebase Console:** Use it to see users and database records in real-time

## 🆘 Need Help?

- Check the [Troubleshooting](#troubleshooting) section
- Read the [Full Documentation](./README.md)
- Check browser console for errors (F12)
- Check backend terminal for errors

---

Happy coding! 🚀
