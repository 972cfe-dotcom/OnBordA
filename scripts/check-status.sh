#!/bin/bash

# Check OnBordA Deployment Status
# Quick health check for all services

set -e

PROJECT_ID="onborda"
REGION="us-central1"
SERVICE_NAME="saas-backend-service"

echo "🔍 OnBordA Status Check"
echo "======================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check gcloud
echo "1. Checking gcloud CLI..."
if command -v gcloud &> /dev/null; then
    echo -e "   ${GREEN}✓${NC} gcloud installed"
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    echo "   Current project: $CURRENT_PROJECT"
else
    echo -e "   ${RED}✗${NC} gcloud not installed"
fi

# Check Firebase CLI
echo ""
echo "2. Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    echo -e "   ${GREEN}✓${NC} firebase-tools installed"
else
    echo -e "   ${RED}✗${NC} firebase-tools not installed"
fi

# Check APIs
echo ""
echo "3. Checking enabled APIs..."
if command -v gcloud &> /dev/null && [ "$CURRENT_PROJECT" = "$PROJECT_ID" ]; then
    
    # Cloud Run
    if gcloud services list --enabled --filter="name:run.googleapis.com" --format="value(name)" 2>/dev/null | grep -q "run.googleapis.com"; then
        echo -e "   ${GREEN}✓${NC} Cloud Run API enabled"
    else
        echo -e "   ${RED}✗${NC} Cloud Run API not enabled"
    fi
    
    # Cloud Build
    if gcloud services list --enabled --filter="name:cloudbuild.googleapis.com" --format="value(name)" 2>/dev/null | grep -q "cloudbuild.googleapis.com"; then
        echo -e "   ${GREEN}✓${NC} Cloud Build API enabled"
    else
        echo -e "   ${RED}✗${NC} Cloud Build API not enabled"
    fi
    
    # Secret Manager
    if gcloud services list --enabled --filter="name:secretmanager.googleapis.com" --format="value(name)" 2>/dev/null | grep -q "secretmanager.googleapis.com"; then
        echo -e "   ${GREEN}✓${NC} Secret Manager API enabled"
    else
        echo -e "   ${RED}✗${NC} Secret Manager API not enabled"
    fi
else
    echo -e "   ${YELLOW}⚠${NC} Skipped (gcloud not configured)"
fi

# Check Service Account
echo ""
echo "4. Checking Service Account..."
if command -v gcloud &> /dev/null && [ "$CURRENT_PROJECT" = "$PROJECT_ID" ]; then
    if gcloud iam service-accounts describe "sa-backend-firebase@onborda.iam.gserviceaccount.com" --project=$PROJECT_ID &>/dev/null; then
        echo -e "   ${GREEN}✓${NC} Service Account exists"
        echo "   Email: sa-backend-firebase@onborda.iam.gserviceaccount.com"
    else
        echo -e "   ${RED}✗${NC} Service Account not found"
    fi
else
    echo -e "   ${YELLOW}⚠${NC} Skipped (gcloud not configured)"
fi

# Check Secret
echo ""
echo "5. Checking Secret Manager..."
if command -v gcloud &> /dev/null && [ "$CURRENT_PROJECT" = "$PROJECT_ID" ]; then
    if gcloud secrets describe firebase-admin-key --project=$PROJECT_ID &>/dev/null; then
        echo -e "   ${GREEN}✓${NC} Secret 'firebase-admin-key' exists"
        VERSION=$(gcloud secrets versions list firebase-admin-key --project=$PROJECT_ID --limit=1 --format="value(name)" 2>/dev/null)
        echo "   Latest version: $VERSION"
    else
        echo -e "   ${RED}✗${NC} Secret 'firebase-admin-key' not found"
    fi
else
    echo -e "   ${YELLOW}⚠${NC} Skipped (gcloud not configured)"
fi

# Check Cloud Run Service
echo ""
echo "6. Checking Cloud Run Backend..."
if command -v gcloud &> /dev/null && [ "$CURRENT_PROJECT" = "$PROJECT_ID" ]; then
    if gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID &>/dev/null; then
        echo -e "   ${GREEN}✓${NC} Backend service deployed"
        SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID --format="value(status.url)" 2>/dev/null)
        echo "   URL: $SERVICE_URL"
        
        # Test health endpoint
        echo ""
        echo "   Testing health endpoint..."
        if curl -s -f "${SERVICE_URL}/api/health" -o /dev/null; then
            echo -e "   ${GREEN}✓${NC} Health check passed"
        else
            echo -e "   ${RED}✗${NC} Health check failed"
        fi
    else
        echo -e "   ${RED}✗${NC} Backend service not deployed"
    fi
else
    echo -e "   ${YELLOW}⚠${NC} Skipped (gcloud not configured)"
fi

# Check Frontend
echo ""
echo "7. Checking Frontend..."
FRONTEND_URL="https://${PROJECT_ID}.web.app"
echo "   Expected URL: $FRONTEND_URL"

if curl -s -f "$FRONTEND_URL" -o /dev/null; then
    echo -e "   ${GREEN}✓${NC} Frontend is accessible"
else
    echo -e "   ${RED}✗${NC} Frontend not accessible"
fi

# Check Firestore
echo ""
echo "8. Checking Firestore..."
if command -v gcloud &> /dev/null && [ "$CURRENT_PROJECT" = "$PROJECT_ID" ]; then
    if gcloud firestore databases list --project=$PROJECT_ID 2>/dev/null | grep -q "default"; then
        echo -e "   ${GREEN}✓${NC} Firestore database exists"
    else
        echo -e "   ${RED}✗${NC} Firestore database not found"
    fi
else
    echo -e "   ${YELLOW}⚠${NC} Skipped (gcloud not configured)"
fi

# Check local files
echo ""
echo "9. Checking local configuration files..."

cd "$(dirname "$0")/.."

# .firebaserc
if [ -f "frontend/.firebaserc" ]; then
    echo -e "   ${GREEN}✓${NC} frontend/.firebaserc exists"
else
    echo -e "   ${RED}✗${NC} frontend/.firebaserc missing"
fi

# firebaseConfig.js
if [ -f "frontend/src/firebaseConfig.js" ]; then
    echo -e "   ${GREEN}✓${NC} frontend/src/firebaseConfig.js exists"
    if grep -q "YOUR_API_KEY" "frontend/src/firebaseConfig.js"; then
        echo -e "   ${YELLOW}⚠${NC} firebaseConfig.js needs configuration"
    fi
else
    echo -e "   ${RED}✗${NC} frontend/src/firebaseConfig.js missing"
fi

# backend .env
if [ -f "backend/.env" ]; then
    echo -e "   ${GREEN}✓${NC} backend/.env exists"
    if grep -q "YOUR_PRIVATE_KEY_HERE" "backend/.env"; then
        echo -e "   ${YELLOW}⚠${NC} backend/.env needs private key"
    fi
else
    echo -e "   ${RED}✗${NC} backend/.env missing"
fi

# cloudbuild.yaml
if [ -f "cloudbuild.yaml" ]; then
    echo -e "   ${GREEN}✓${NC} cloudbuild.yaml exists"
else
    echo -e "   ${RED}✗${NC} cloudbuild.yaml missing"
fi

# Summary
echo ""
echo "=============================="
echo "📊 Status Summary"
echo "=============================="
echo ""

if command -v gcloud &> /dev/null && [ "$CURRENT_PROJECT" = "$PROJECT_ID" ]; then
    if gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID &>/dev/null; then
        echo "🟢 Backend: DEPLOYED"
        SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID --format="value(status.url)" 2>/dev/null)
        echo "   $SERVICE_URL"
    else
        echo "🔴 Backend: NOT DEPLOYED"
    fi
else
    echo "🟡 Backend: UNKNOWN (gcloud not configured)"
fi

if curl -s -f "https://${PROJECT_ID}.web.app" -o /dev/null; then
    echo "🟢 Frontend: DEPLOYED"
    echo "   https://${PROJECT_ID}.web.app"
else
    echo "🔴 Frontend: NOT DEPLOYED"
fi

echo ""
echo "For detailed deployment instructions, see:"
echo "  - DEPLOYMENT_INSTRUCTIONS.md"
echo "  - scripts/README.md"
echo ""
