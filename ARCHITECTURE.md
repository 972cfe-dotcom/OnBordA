# 🏗️ Architecture Documentation

## System Overview

This document describes the architecture of the SaaS application, including components, data flow, and scalability considerations.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                           GitHub Repository                          │
│                                                                       │
│  ┌──────────────┐                           ┌──────────────┐        │
│  │   Frontend   │                           │   Backend    │        │
│  │  (React SPA) │                           │ (Node.js API)│        │
│  └──────────────┘                           └──────────────┘        │
└────────┬────────────────────────────────────────────┬───────────────┘
         │                                             │
         │ GitHub Actions (CI/CD)                     │ GitHub Actions
         │                                             │
         ▼                                             ▼
┌─────────────────┐                          ┌─────────────────┐
│ Firebase Hosting│                          │   Cloud Run     │
│   (CDN Global)  │                          │  (Container)    │
│                 │                          │                 │
│  - React App    │                          │ - Express API   │
│  - Static Files │                          │ - Auto-scaling  │
│  - HTTPS Auto   │                          │ - Min: 0        │
└────────┬────────┘                          │ - Max: 10+      │
         │                                   └────────┬────────┘
         │                                            │
         │                                            │
         │                                            ▼
         │                                   ┌────────────────┐
         │                                   │ Firebase Admin │
         │                                   │      SDK       │
         │                                   └────────┬───────┘
         │                                            │
         │                                            │
         └─────────────┬──────────────────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  Firebase Auth  │
              │                 │
              │ - Email/Pass    │
              │ - Social Login  │
              │ - JWT Tokens    │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │    Firestore    │
              │                 │
              │ - users         │
              │ - userdata      │
              │ - NoSQL Cloud   │
              │ - Auto-scaling  │
              └─────────────────┘
```

## Component Details

### 1. Frontend (React SPA)

**Technology Stack:**
- React 18
- Vite (Build tool)
- Firebase SDK (Client)
- Axios (HTTP client)

**Responsibilities:**
- User interface and experience
- Client-side routing
- Firebase Authentication integration
- API calls to backend
- State management

**Key Files:**
- `App.jsx` - Main application component
- `firebase.js` - Firebase SDK initialization
- `firebaseConfig.js` - Configuration values

**Deployment:**
- Firebase Hosting
- Global CDN distribution
- HTTPS by default
- Auto-scaling

**URLs:**
- Production: `https://PROJECT_ID.web.app`
- Alternative: `https://PROJECT_ID.firebaseapp.com`

---

### 2. Backend (Node.js API)

**Technology Stack:**
- Node.js 18+
- Express.js
- Firebase Admin SDK
- Docker

**Responsibilities:**
- Business logic
- API endpoints
- JWT token verification
- Database operations (Firestore)
- User authentication validation

**Key Components:**

#### Server (`src/server.js`)
- Express app initialization
- CORS configuration
- Route registration
- Error handling

#### Firebase Admin (`src/firebaseAdmin.js`)
- Firebase Admin SDK initialization
- Firestore connection
- Auth service connection

#### Authentication Middleware (`src/middleware/auth.js`)
- JWT token extraction
- Token verification with Firebase
- User identity extraction

#### API Routes (`src/routes/api.js`)
- `/api/health` - Health check (public)
- `/api/protected` - Protected endpoint (requires auth)
- `/api/data` - CRUD operations (requires auth)

**Deployment:**
- Cloud Run (managed containers)
- Auto-scaling: 0-10+ instances
- 512Mi memory, 1 CPU
- Container registry: GCR

**URL:**
- `https://saas-backend-[hash]-uc.a.run.app`

---

### 3. Authentication (Firebase Auth)

**Features:**
- Email/Password authentication
- Social login providers (Google, GitHub, etc.)
- JWT token generation
- Token refresh
- Email verification
- Password reset

**Flow:**

```
┌──────────┐         ┌──────────────┐         ┌──────────┐
│ Frontend │────────▶│ Firebase Auth│────────▶│  Backend │
│          │ Sign In │              │ Verify  │          │
│          │◀────────│ Returns JWT  │ Token   │          │
└──────────┘         └──────────────┘         └──────────┘
```

1. User signs in via frontend
2. Firebase Auth validates credentials
3. Returns JWT token to frontend
4. Frontend includes token in API calls
5. Backend verifies token with Firebase Admin

---

### 4. Database (Firestore)

**Type:** NoSQL Document Database

**Collections:**

#### `users` Collection
```javascript
{
  userId: "uid-123",
  email: "user@example.com",
  createdAt: "2024-01-01T00:00:00.000Z",
  lastLogin: "2024-01-01T12:00:00.000Z"
}
```

#### `userdata` Collection
```javascript
{
  id: "doc-id",
  userId: "uid-123",
  data: "user's data",
  createdAt: "2024-01-01T00:00:00.000Z"
}
```

**Security Rules:**
```javascript
// Users can only read/write their own data
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
}

// User data is scoped to owner
match /userdata/{docId} {
  allow read, write: if request.auth.uid == resource.data.userId;
}
```

---

## Data Flow

### User Registration Flow

```
1. User enters email/password in Frontend
2. Frontend → Firebase Auth: createUserWithEmailAndPassword()
3. Firebase Auth creates user account
4. Firebase Auth returns JWT token
5. Frontend stores token
6. Frontend → Backend: GET /api/protected (with JWT)
7. Backend verifies JWT with Firebase Admin
8. Backend creates user document in Firestore
9. Backend → Frontend: User data
10. Frontend displays welcome screen
```

### API Call Flow

```
1. Frontend needs data
2. Frontend gets JWT token from Firebase Auth
3. Frontend → Backend: API call with "Authorization: Bearer JWT"
4. Backend extracts JWT from header
5. Backend → Firebase Admin: verifyIdToken(JWT)
6. Firebase Admin validates token
7. Backend receives user info (uid, email)
8. Backend queries Firestore for user data
9. Backend → Frontend: Returns data
10. Frontend updates UI
```

---

## Scalability Architecture

### Frontend Scalability

**Firebase Hosting Features:**
- **Global CDN**: Serves content from edge locations worldwide
- **Automatic HTTPS**: SSL certificates managed automatically
- **Compression**: Gzip/Brotli compression enabled
- **Caching**: Static assets cached at edge
- **Custom Domains**: Support for custom domains with auto-SSL

**Performance:**
- Handles millions of requests per day
- < 100ms response time globally
- 99.99% uptime SLA

---

### Backend Scalability

**Cloud Run Auto-Scaling:**

```
Request Load          | Instances | Response
─────────────────────────────────────────────
0 requests           | 0         | Cold start (~1-2s)
1-10 req/sec         | 1         | < 100ms
10-100 req/sec       | 2-5       | < 100ms
100-1000 req/sec     | 5-10      | < 200ms
1000+ req/sec        | 10+       | Horizontal scaling
```

**Configuration:**
```yaml
min-instances: 0     # Cost optimization
max-instances: 10    # Prevent runaway costs
concurrency: 80      # Requests per instance
memory: 512Mi        # Memory per instance
cpu: 1               # CPU per instance
timeout: 300s        # Request timeout
```

**Scaling Triggers:**
- CPU utilization > 60%
- Memory utilization > 70%
- Request queue depth > 10

---

### Database Scalability

**Firestore Features:**
- **Automatic Scaling**: Handles any load automatically
- **Distributed**: Data replicated across regions
- **Indexing**: Composite indexes for complex queries
- **Real-time**: WebSocket connections for live updates

**Performance:**
- 1M+ reads/writes per second (per collection)
- < 10ms read latency
- < 50ms write latency
- Automatic sharding and rebalancing

**Limits:**
- Max document size: 1MB
- Max batch size: 500 operations
- Max write rate: 1000/second per document

---

## Security Architecture

### 1. Authentication Security

**Firebase Auth:**
- Industry-standard OAuth 2.0
- Secure password hashing (bcrypt)
- Token-based authentication (JWT)
- Automatic token refresh
- Session management

**Backend Verification:**
```javascript
// Every protected endpoint verifies JWT
const token = req.headers.authorization.split('Bearer ')[1];
const decodedToken = await admin.auth().verifyIdToken(token);
// Only proceed if valid
```

### 2. Network Security

**Frontend:**
- HTTPS only (enforced by Firebase Hosting)
- Content Security Policy (CSP)
- CORS configured on backend

**Backend:**
```javascript
// CORS whitelist
const allowedOrigins = [
  'https://PROJECT_ID.web.app',
  'https://PROJECT_ID.firebaseapp.com'
];
```

### 3. Database Security

**Firestore Rules:**
```javascript
// Users can only access their own data
allow read, write: if request.auth.uid == userId;

// Additional validations
allow create: if request.auth != null 
              && request.resource.data.userId == request.auth.uid;
```

### 4. Environment Security

**Secrets Management:**
- GitHub Secrets for CI/CD
- Environment variables for runtime
- No secrets in code
- Service account key rotation

---

## Cost Optimization

### Estimated Monthly Costs (1000 active users)

| Service            | Usage                  | Cost      |
|--------------------|------------------------|-----------|
| Firebase Hosting   | 10GB transfer          | Free      |
| Firebase Auth      | 1000 users             | Free      |
| Firestore          | 1M reads, 500K writes  | $10       |
| Cloud Run          | 100K requests          | $5        |
| **Total**          |                        | **~$15**  |

### Cost Optimization Tips

1. **Cloud Run:**
   - Set `min-instances: 0` to avoid idle costs
   - Use `max-instances` to prevent runaway costs
   - Optimize cold start time

2. **Firestore:**
   - Use batch operations
   - Implement client-side caching
   - Optimize queries with indexes
   - Delete unused data

3. **Hosting:**
   - Use Firebase Hosting (free tier generous)
   - Enable compression
   - Implement browser caching

---

## Monitoring and Observability

### Metrics to Track

**Frontend:**
- Page load time
- Time to interactive
- API call success rate
- User authentication success rate

**Backend:**
- Request count
- Response time (p50, p95, p99)
- Error rate
- Instance count
- Memory usage
- CPU usage

**Database:**
- Read/write operations
- Query latency
- Index efficiency

### Logging

**Cloud Run Logs:**
```javascript
console.log('Info:', { userId, action });
console.error('Error:', { error, context });
```

**Log Levels:**
- `INFO`: Normal operations
- `WARN`: Recoverable issues
- `ERROR`: Failures requiring attention

### Alerts

Set up alerts for:
- Error rate > 5%
- Response time > 1 second
- Instance count > 8 (cost control)
- Firestore costs > threshold

---

## Disaster Recovery

### Backup Strategy

**Firestore:**
- Automatic daily backups
- Export to Cloud Storage
- Retention: 30 days

**Code:**
- Git repository
- Tagged releases
- Branch protection

### Recovery Procedures

**Frontend Down:**
1. Check Firebase Hosting status
2. Verify DNS configuration
3. Re-deploy from Git

**Backend Down:**
1. Check Cloud Run status page
2. View logs in Cloud Logging
3. Roll back to previous revision
4. Scale up instances if needed

**Database Issues:**
1. Check Firestore status
2. Verify security rules
3. Restore from backup if needed

---

## Future Enhancements

### Phase 1 (MVP) ✅
- [x] User authentication
- [x] Basic CRUD operations
- [x] Auto-scaling infrastructure
- [x] CI/CD pipeline

### Phase 2 (Scale)
- [ ] Custom domains
- [ ] Email verification
- [ ] Password reset
- [ ] User profile management
- [ ] Rate limiting
- [ ] API versioning

### Phase 3 (Advanced)
- [ ] Multi-region deployment
- [ ] CDN optimization
- [ ] Advanced monitoring
- [ ] A/B testing
- [ ] Performance optimization
- [ ] Cloud Armor (DDoS protection)

### Phase 4 (Enterprise)
- [ ] Multi-tenancy
- [ ] Advanced analytics
- [ ] Audit logging
- [ ] Compliance (GDPR, SOC 2)
- [ ] SLA monitoring
- [ ] Disaster recovery automation

---

## Technology Decisions

### Why Firebase Hosting?
- ✅ Global CDN
- ✅ Auto HTTPS
- ✅ Free tier generous
- ✅ Integrated with Firebase ecosystem
- ✅ Simple deployment

### Why Cloud Run?
- ✅ Serverless (no server management)
- ✅ Auto-scaling (0 to thousands)
- ✅ Pay-per-use (cost effective)
- ✅ Container-based (flexible)
- ✅ Integrated with GCP

### Why Firestore?
- ✅ Serverless database
- ✅ Real-time capabilities
- ✅ Auto-scaling
- ✅ Strong consistency
- ✅ Built-in security rules

### Why React?
- ✅ Popular and well-documented
- ✅ Large ecosystem
- ✅ Fast with Vite
- ✅ Easy to learn

---

For implementation details, see [README.md](./README.md)
For deployment instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md)
