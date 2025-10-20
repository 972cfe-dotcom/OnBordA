# GitHub Actions Workflows

Due to GitHub App permission restrictions, the workflow files cannot be pushed automatically.

## Manual Setup Instructions

To enable automated CI/CD with GitHub Actions, you need to manually create these workflow files:

### 1. Create `.github/workflows/deploy-frontend.yml`

Copy the content from `docs/workflows/deploy-frontend.yml` to `.github/workflows/deploy-frontend.yml` in your repository.

### 2. Create `.github/workflows/deploy-backend.yml`

Copy the content from `docs/workflows/deploy-backend.yml` to `.github/workflows/deploy-backend.yml` in your repository.

## How to Add Workflows

### Option 1: Via GitHub Web Interface

1. Go to your repository on GitHub
2. Click "Add file" → "Create new file"
3. Name it `.github/workflows/deploy-frontend.yml`
4. Paste the content from `docs/workflows/deploy-frontend.yml`
5. Click "Commit new file"
6. Repeat for `deploy-backend.yml`

### Option 2: Via Git (with proper permissions)

```bash
# Copy workflows to correct location
cp docs/workflows/*.yml .github/workflows/

# Commit and push
git add .github/workflows/
git commit -m "ci: Add GitHub Actions workflows"
git push
```

### Option 3: Via GitHub CLI

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/OWNER/REPO/contents/.github/workflows/deploy-frontend.yml \
  -f message="ci: Add frontend deployment workflow" \
  -f content="$(base64 docs/workflows/deploy-frontend.yml)"
```

## Required GitHub Secrets

Before the workflows can run, you need to add these secrets to your repository:

Go to: Settings → Secrets and variables → Actions → New repository secret

### Frontend Secrets:
- `FIREBASE_SERVICE_ACCOUNT` - Firebase service account JSON
- `FIREBASE_PROJECT_ID` - Your Firebase project ID
- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_STORAGE_BUCKET`
- `VITE_FIREBASE_MESSAGING_SENDER_ID`
- `VITE_FIREBASE_APP_ID`
- `VITE_API_URL` - Your Cloud Run service URL

### Backend Secrets:
- `GCP_PROJECT_ID` - Google Cloud project ID
- `GCP_WORKLOAD_IDENTITY_PROVIDER` - Workload identity provider
- `GCP_SERVICE_ACCOUNT` - Service account email
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `ALLOWED_ORIGINS` - Comma-separated allowed origins

## Workflow Files

The workflow files are located in `docs/workflows/`:
- `deploy-frontend.yml` - Deploys frontend to Firebase Hosting
- `deploy-backend.yml` - Deploys backend to Cloud Run

See [DEPLOYMENT.md](../DEPLOYMENT.md) for complete deployment instructions.
