# ✅ רשימת משימות מהירה - OnBordA

## 🎯 מה שצריך לעשות עכשיו

### 1️⃣ תיקון הרשאות (5 דקות)

```bash
cd /path/to/OnBordA/scripts
./quick-fix-permissions.sh
```

זה יתקן אוטומטית:
- ✅ הפעלת כל ה-APIs הנדרשים
- ✅ הוספת כל ההרשאות ל-Service Account
- ✅ הוספת הרשאות ל-Cloud Build

### 2️⃣ יצירת Firebase Web App (3 דקות)

1. פתח: https://console.firebase.google.com/project/onborda/settings/general
2. לחץ על `</>` (Web)
3. שם: `OnBordA Web App`
4. סמן: "Also set up Firebase Hosting"
5. העתק את הערכים:
   ```
   apiKey: "..."
   messagingSenderId: "..."
   appId: "..."
   ```

### 3️⃣ הורד Service Account Key (2 דקות)

1. פתח: https://console.cloud.google.com/iam-admin/serviceaccounts?project=onborda
2. בחר: `sa-backend-firebase@onborda.iam.gserviceaccount.com`
3. Actions (⋮) → Manage keys → Add Key → Create new key → JSON
4. שמור את הקובץ (לדוגמה: `~/Downloads/onborda-key.json`)

### 4️⃣ הגדרת Secrets (3 דקות)

```bash
cd /path/to/OnBordA/scripts
./setup-secrets.sh
```

כשיבקש נתיב, הזן:
```
~/Downloads/onborda-key.json
```

### 5️⃣ עדכון Frontend Config (2 דקות)

ערוך: `frontend/src/firebaseConfig.js`

החלף:
```javascript
apiKey: "YOUR_API_KEY",           // מהשלב 2
messagingSenderId: "YOUR_SENDER_ID",  // מהשלב 2
appId: "YOUR_APP_ID"              // מהשלב 2
```

Commit:
```bash
git add frontend/src/firebaseConfig.js
git commit -m "chore: Update Firebase configuration"
git push origin main
```

### 6️⃣ פריסה (10 דקות)

```bash
cd /path/to/OnBordA/scripts
./deploy.sh
```

בחר: `3` (Both Backend and Frontend)

### 7️⃣ בדיקה (1 דקה)

```bash
cd /path/to/OnBordA/scripts
./check-status.sh
```

פתח בדפדפן: https://onborda.web.app

---

## 🔍 אבחון בעיות

```bash
cd /path/to/OnBordA/scripts
./diagnose.sh
```

זה יראה בדיוק מה חסר ומה צריך לעשות.

---

## 📚 מסמכים מפורטים

- **מדריך מלא:** `COMPLETE_SETUP_GUIDE_HEBREW.md`
- **התחלה מהירה:** `QUICK_START_HEBREW.md`
- **סטטוס פרויקט:** `STATUS.md`

---

## ⚠️ בעיות נפוצות

### Build נכשל
```bash
# הרץ את תיקון ההרשאות
./quick-fix-permissions.sh
```

### Frontend לא מתחבר ל-Backend
1. בדוק ש-API_URL ב-`firebaseConfig.js` נכון
2. בדוק ש-ALLOWED_ORIGINS ב-Backend כולל את Frontend URL

### Authentication לא עובד
1. ודא ש-Firebase Auth מופעל
2. ודא ש-Email/Password provider מופעל
3. בדוק ש-`firebaseConfig.js` מכיל ערכים נכונים

---

## 🎉 סיימת!

אם עקבת אחרי כל השלבים, האפליקציה שלך אמורה להיות זמינה ב:

- **Frontend:** https://onborda.web.app
- **Backend:** https://saas-backend-service-xxx-uc.a.run.app

---

**זמן כולל: ~30 דקות**

**קושי: קל-בינוני** (רוב השלבים אוטומטיים)
