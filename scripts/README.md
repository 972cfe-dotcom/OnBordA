# 🛠️ Deployment Scripts

סקריפטים לאוטומציה של תהליך הפריסה של OnBordA.

## 📋 סקריפטים זמינים

### 🆕 סקריפטים חדשים (מומלץ להתחלה!)

#### 1. `diagnose.sh` - אבחון מצב הפרויקט ⭐

בודק את המצב הנוכחי ומציג מה חסר.

**שימוש:**
```bash
cd scripts
./diagnose.sh
```

**מה הסקריפט בודק:**
- ✅ CLI tools (gcloud, firebase, npm)
- ✅ Authentication status
- ✅ Google Cloud APIs enabled
- ✅ Service Account permissions
- ✅ Secrets configuration
- ✅ Backend deployment
- ✅ Frontend configuration
- ✅ Firebase Hosting deployment

**פלט:** דוח מפורט עם כל הבעיות והפתרונות

#### 2. `quick-fix-permissions.sh` - תיקון אוטומטי של הרשאות ⭐

מתקן אוטומטית את כל הבעיות שזוהו בתמונות שהעלית.

**שימוש:**
```bash
cd scripts
./quick-fix-permissions.sh
```

**מה הסקריפט מתקן:**
- ✅ מפעיל את כל ה-APIs הנדרשים
- ✅ מוסיף logging.viewer, logging.logWriter
- ✅ מוסיף roles/run.admin
- ✅ מוסיף roles/secretmanager.secretAccessor
- ✅ מוסיף roles/firebase.admin
- ✅ מתקן הרשאות Cloud Build Service Account

**זמן: ~2 דקות**

---

### סקריפטים מקוריים

#### 3. `setup-secrets.sh` - הגדרת Secrets

מגדיר את Secret Manager ומעלה את ה-Service Account credentials.

**שימוש:**
```bash
cd scripts
./setup-secrets.sh
```

**מה הסקריפט עושה:**
- ✅ Enable APIs נדרשים (Secret Manager, Cloud Build, Cloud Run)
- ✅ יוצר Secret ב-Secret Manager מה-Service Account JSON
- ✅ נותן הרשאות ל-Cloud Build לגשת ל-Secret
- ✅ מעדכן את `backend/.env` עם ה-Private Key

**דרישות מוקדמות:**
- `gcloud` CLI מותקן ומחובר
- Service Account JSON key מוריד מ-Google Cloud Console

#### 4. `deploy.sh` - פריסה מלאה

מפרוס את Backend ו/או Frontend.

**שימוש:**
```bash
cd scripts
./deploy.sh
```

**אפשרויות:**
1. **Backend only** - רק Cloud Run
2. **Frontend only** - רק Firebase Hosting  
3. **Both** - Backend + Frontend
4. **Just build** - בניה מקומית בלבד

**מה הסקריפט עושה:**

**Backend:**
- 🔨 בונה Docker image
- 📦 מעלה ל-Container Registry
- 🚀 מפרוס ל-Cloud Run
- 🏥 בודק health endpoint
- 📋 מציג את ה-URL

**Frontend:**
- 📦 מתקין dependencies
- 🔨 בונה את האפליקציה
- 🚀 מפרוס ל-Firebase Hosting
- 📋 מציג את ה-URL

#### 5. `check-status.sh` - בדיקת סטטוס

בודק אם הכל עובד אחרי הפריסה.

**שימוש:**
```bash
cd scripts
./check-status.sh
```

---

## 🚀 תהליך הפריסה המלא (מעודכן!)

### תהליך מהיר (מומלץ!)

```bash
# שלב 0: אבחון
cd scripts
./diagnose.sh

# שלב 1: תיקון הרשאות
./quick-fix-permissions.sh

# שלב 2: צור Firebase Web App (ידני)
# https://console.firebase.google.com/project/onborda/settings/general

# שלב 3: צור Service Account Key (ידני)
# https://console.cloud.google.com/iam-admin/serviceaccounts?project=onborda

# שלב 4: הגדר Secrets
./setup-secrets.sh

# שלב 5: עדכן Frontend Config (ידני)
# ערוך frontend/src/firebaseConfig.js

# שלב 6: פרוס הכל
./deploy.sh  # בחר 3 (Both)

# שלב 7: בדיקה
./check-status.sh
```

### תהליך מפורט (שלב אחר שלב)

### שלב 1: הכנה ראשונית

```bash
# 1. Login to gcloud
gcloud auth login

# 2. Set project
gcloud config set project onborda

# 3. Login to Firebase
firebase login
```

### שלב 2: הגדרת Secrets

```bash
cd scripts
./setup-secrets.sh
```

עקוב אחרי ההוראות:
1. הורד את Service Account JSON key מ-Google Cloud Console
2. ספק את הנתיב לקובץ כשהסקריפט ישאל

### שלב 3: עדכון Firebase Config

ערוך `frontend/src/firebaseConfig.js` והוסף:
- `apiKey`
- `messagingSenderId`
- `appId`

אלה מגיעים מ-Firebase Console → Project Settings → Your apps.

### שלב 4: פריסה

```bash
cd scripts
./deploy.sh
```

בחר אפשרות 3 (Both) כדי לפרוס הכל.

### שלב 5: בדיקה

**Backend:**
```bash
curl https://saas-backend-service-xxx.run.app/api/health
```

**Frontend:**
פתח בדפדפן: `https://onborda.web.app`

## 📝 הערות חשובות

### Service Account Permissions

ודא שה-Service Account יש לו:
- ✅ `roles/firebase.admin` (Firebase Admin)
- ✅ `roles/datastore.user` (Firestore)
- ✅ `roles/secretmanager.secretAccessor` (Secret Manager)

### Environment Variables

ה-Backend צריך את המשתנים הבאים:
```
NODE_ENV=production
PORT=8080
FIREBASE_PROJECT_ID=onborda
FIREBASE_CLIENT_EMAIL=sa-backend-firebase@onborda.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="..."
ALLOWED_ORIGINS=https://onborda.web.app,https://onborda.firebaseapp.com
```

### CORS Configuration

אחרי שה-Frontend מפורס, ודא ש-`ALLOWED_ORIGINS` כולל:
- `https://onborda.web.app`
- `https://onborda.firebaseapp.com`

## 🐛 פתרון בעיות

### "gcloud: command not found"

התקן את Google Cloud CLI:
```bash
# On macOS
brew install --cask google-cloud-sdk

# On Linux
curl https://sdk.cloud.google.com | bash
```

### "firebase: command not found"

התקן Firebase CLI:
```bash
npm install -g firebase-tools
```

### Build נכשל

צפה בלוגים:
```bash
gcloud builds list --project=onborda --limit=5
gcloud builds log BUILD_ID --project=onborda
```

### שגיאת Authentication

ודא:
1. Service Account קיים
2. Private Key נכון ב-`.env`
3. Secret Manager מוגדר

### שגיאת CORS

עדכן `backend/.env`:
```env
ALLOWED_ORIGINS=https://onborda.web.app,https://onborda.firebaseapp.com,http://localhost:3000
```

ופרוס מחדש את ה-Backend.

## 🔄 CI/CD Automation (אופציונלי)

לאוטומציה מלאה, הגדר Cloud Build Triggers:

1. [Cloud Build Triggers](https://console.cloud.google.com/cloud-build/triggers)
2. Create Trigger
3. Connect Repository
4. Trigger על push ל-`main` branch
5. Build configuration: `cloudbuild.yaml`

עכשיו כל push ל-GitHub יפרוס אוטומטית! 🎉

## 📚 משאבים נוספים

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
- [Secret Manager](https://cloud.google.com/secret-manager/docs)
- [Cloud Build](https://cloud.google.com/build/docs)

---

נוצר עבור פרויקט OnBordA 🚀
