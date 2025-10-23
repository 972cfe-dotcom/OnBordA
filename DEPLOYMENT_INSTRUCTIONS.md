# 🚀 הוראות פריסה למערכת OnBordA

## 📊 מצב נוכחי

### ✅ מה שכבר הושלם:
1. **Firebase Project**: פרויקט OnBordA מוגדר ✅
2. **Service Account**: `sa-backend-firebase@onborda.iam.gserviceaccount.com` ✅  
3. **Firebase Config**: קובץ `.firebaserc` נוצר עם project ID ✅
4. **Backend Structure**: קוד Backend מוכן עם Dockerfile ✅
5. **Cloud Build Config**: `cloudbuild.yaml` מוגדר ומוכן ✅

### ⚠️ מה שצריך להשלים ידנית:

## שלב 1: השלמת Firebase Configuration

### 1.1 קבלת Firebase Web App Config

1. כנס ל-[Firebase Console](https://console.firebase.google.com/)
2. בחר את הפרויקט **OnBordA**
3. לחץ על הגלגל ⚙️ → **Project Settings**
4. גלול ל-**Your apps**
5. אם אין אפליקציית Web, לחץ על `</>` (Web icon)
6. תן שם: `onborda-web-app`
7. לחץ **Register app**
8. העתק את האובייקט `firebaseConfig`:

```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "onborda.firebaseapp.com",
  projectId: "onborda",
  storageBucket: "onborda.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc..."
};
```

### 1.2 עדכון קובץ Frontend Config

ערוך את הקובץ: `frontend/src/firebaseConfig.js`

החלף את הערכים:
- `YOUR_API_KEY` → ה-apiKey שלך
- `YOUR_SENDER_ID` → ה-messagingSenderId שלך  
- `YOUR_APP_ID` → ה-appId שלך

## שלב 2: הגדרת Secret Manager ל-Private Key

### 2.1 קבלת Service Account Private Key

מהתמונה שלך אני רואה שכבר יש לך Service Account. עכשיו צריך:

1. כנס ל-[Google Cloud Console](https://console.cloud.google.com/)
2. בחר פרויקט **OnBordA**
3. IAM & Admin → Service Accounts
4. מצא את: `sa-backend-firebase@onborda.iam.gserviceaccount.com`
5. לחץ על שלוש הנקודות → **Manage keys**
6. Add Key → Create new key
7. בחר **JSON**
8. לחץ **Create**
9. הקובץ יוריד - **שמור אותו בטוח!**

### 2.2 יצירת Secret ב-Secret Manager

הרץ את הפקודות הבאות (צריך `gcloud` מותקן):

```bash
# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com --project=onborda

# Create secret from the downloaded JSON key file
gcloud secrets create firebase-admin-key \
  --data-file=/path/to/downloaded-key.json \
  --project=onborda

# Grant Cloud Build access to the secret
PROJECT_NUMBER=$(gcloud projects describe onborda --format="value(projectNumber)")
gcloud secrets add-iam-policy-binding firebase-admin-key \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=onborda
```

### 2.3 עדכון cloudbuild.yaml להשתמש ב-Secret

הקובץ כבר מוכן, אבל אם צריך לעדכן את ה-PRIVATE_KEY, תצטרך:

```yaml
availableSecrets:
  secretManager:
  - versionName: projects/onborda/secrets/firebase-admin-key/versions/latest
    env: 'FIREBASE_ADMIN_KEY'
```

## שלב 3: הפעלת Cloud Build והפריסה

### 3.1 Enable Required APIs

```bash
gcloud services enable cloudbuild.googleapis.com --project=onborda
gcloud services enable run.googleapis.com --project=onborda
gcloud services enable containerregistry.googleapis.com --project=onborda
```

### 3.2 הרצת Cloud Build

יש שתי אפשרויות:

**אפשרות א': דרך GitHub (מומלץ)**
- ה-Build יתחיל אוטומטית עם כל push ל-main
- אם הגדרת Cloud Build Trigger בקונסול

**אפשרות ב': ידני דרך gcloud**

```bash
cd /path/to/webapp
gcloud builds submit --config=cloudbuild.yaml --project=onborda
```

### 3.3 צפייה בלוגים

```bash
# List builds
gcloud builds list --project=onborda

# View specific build logs
gcloud builds log BUILD_ID --project=onborda
```

## שלב 4: קבלת Cloud Run URL ועדכון Frontend

### 4.1 קבלת ה-URL של Backend

לאחר Deploy מוצלח:

```bash
gcloud run services describe saas-backend-service \
  --region=us-central1 \
  --project=onborda \
  --format="value(status.url)"
```

או בקונסול:
1. [Cloud Run Console](https://console.cloud.google.com/run)
2. בחר `saas-backend-service`
3. העתק את ה-URL (משהו כמו: `https://saas-backend-service-xxx.run.app`)

### 4.2 עדכון Frontend Config

ערוך `frontend/src/firebaseConfig.js`:

```javascript
export const API_URL = process.env.VITE_API_URL || "https://saas-backend-service-xxx.run.app";
```

החלף `xxx` ב-URL האמיתי שקיבלת.

## שלב 5: פריסת Frontend ל-Firebase Hosting

### 5.1 התקנת Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### 5.2 בניה ופריסה

```bash
cd frontend

# Build the app
npm install
npm run build

# Deploy to Firebase Hosting
firebase deploy --only hosting --project onborda
```

### 5.3 קבלת ה-URL

לאחר Deploy מוצלח תקבל:
```
✔ Deploy complete!

Project Console: https://console.firebase.google.com/project/onborda/overview
Hosting URL: https://onborda.web.app
```

## שלב 6: בדיקות

### 6.1 בדיקת Backend

```bash
curl https://saas-backend-service-xxx.run.app/api/health
```

תקבל:
```json
{
  "status": "healthy",
  "message": "Backend API is running",
  "timestamp": "2024-10-23T..."
}
```

### 6.2 בדיקת Frontend

1. פתח: `https://onborda.web.app`
2. לחץ **Sign Up**
3. הכנס email וסיסמה
4. וודא שהרישום עובד
5. לחץ **Call Protected API**
6. וודא שה-API call עובד

## שלב 7: Firestore Security Rules

1. [Firestore Console](https://console.firebase.google.com/project/onborda/firestore)
2. לחץ **Rules**
3. עדכן לכללים האלה:

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
      allow read: if request.auth != null && 
                     resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               resource.data.userId == request.auth.uid;
    }
  }
}
```

4. לחץ **Publish**

## 🎯 סיכום - Checklist

- [ ] השג Firebase Web App Config והעתק ל-`firebaseConfig.js`
- [ ] הורד Service Account JSON key
- [ ] צור Secret ב-Secret Manager
- [ ] Enable APIs: Cloud Build, Cloud Run, Container Registry
- [ ] הרץ Cloud Build (ידני או דרך GitHub)
- [ ] קבל Cloud Run URL
- [ ] עדכן Frontend עם Backend URL
- [ ] Deploy Frontend ל-Firebase Hosting
- [ ] בדוק Backend health endpoint
- [ ] בדוק Frontend - Sign Up ו-API calls
- [ ] עדכן Firestore Security Rules

## 📞 פתרון בעיות נפוצות

### Build נכשל

```bash
# Check build logs
gcloud builds list --project=onborda --limit=5
gcloud builds log BUILD_ID --project=onborda
```

### שגיאת Authentication

וודא ש:
- Service Account יש לו הרשאות Firebase Admin
- Secret Manager מוגדר נכון
- Environment variables מועברים נכון ל-Cloud Run

### שגיאות CORS

וודא:
- `ALLOWED_ORIGINS` כולל את ה-Frontend URLs
- Frontend משתמש ב-URL הנכון של Backend

### שגיאות Firestore

וודא:
- Firestore Database נוצר
- Security Rules מוגדרים נכון
- Authentication פועל

## 🆘 זקוק לעזרה?

- [Firebase Documentation](https://firebase.google.com/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)

---

**הערה חשובה**: שמור את ה-Service Account JSON key במקום בטוח ואל תעלה אותו ל-Git!
