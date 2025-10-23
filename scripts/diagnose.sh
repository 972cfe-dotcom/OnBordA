#!/bin/bash

# OnBordA - Diagnostic Script
# This script checks the current state and identifies what needs to be done

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ID="onborda"
SERVICE_ACCOUNT="sa-backend-firebase@onborda.iam.gserviceaccount.com"
BACKEND_SERVICE="saas-backend-service"
REGION="us-central1"

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}   OnBordA - Diagnostic & Setup Checker${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Function to check command existence
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        return 1
    fi
}

# Function to check gcloud authentication
check_gcloud_auth() {
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -n 1)
        if [ -n "$ACTIVE_ACCOUNT" ]; then
            echo -e "${GREEN}✓${NC} gcloud authenticated as: $ACTIVE_ACCOUNT"
            return 0
        fi
    fi
    echo -e "${RED}✗${NC} gcloud is NOT authenticated"
    return 1
}

# Function to check if API is enabled
check_api() {
    API=$1
    if gcloud services list --enabled --project=$PROJECT_ID 2>/dev/null | grep -q "$API"; then
        echo -e "${GREEN}✓${NC} $API is enabled"
        return 0
    else
        echo -e "${RED}✗${NC} $API is NOT enabled"
        return 1
    fi
}

# Function to check IAM role
check_iam_role() {
    MEMBER=$1
    ROLE=$2
    if gcloud projects get-iam-policy $PROJECT_ID \
        --flatten="bindings[].members" \
        --filter="bindings.members:$MEMBER AND bindings.role:$ROLE" \
        --format="value(bindings.role)" 2>/dev/null | grep -q "$ROLE"; then
        echo -e "${GREEN}✓${NC} $MEMBER has $ROLE"
        return 0
    else
        echo -e "${RED}✗${NC} $MEMBER MISSING $ROLE"
        return 1
    fi
}

# Function to check if secret exists
check_secret() {
    SECRET_NAME=$1
    if gcloud secrets describe $SECRET_NAME --project=$PROJECT_ID &> /dev/null; then
        echo -e "${GREEN}✓${NC} Secret '$SECRET_NAME' exists"
        return 0
    else
        echo -e "${RED}✗${NC} Secret '$SECRET_NAME' does NOT exist"
        return 1
    fi
}

# Function to check Cloud Run service
check_cloud_run_service() {
    if gcloud run services describe $BACKEND_SERVICE \
        --region=$REGION \
        --project=$PROJECT_ID &> /dev/null; then
        URL=$(gcloud run services describe $BACKEND_SERVICE \
            --region=$REGION \
            --project=$PROJECT_ID \
            --format='value(status.url)' 2>/dev/null)
        echo -e "${GREEN}✓${NC} Backend deployed at: $URL"
        
        # Try to hit health endpoint
        if curl -s -f -m 5 "$URL/api/health" &> /dev/null; then
            echo -e "${GREEN}✓${NC} Backend health check passed"
        else
            echo -e "${YELLOW}⚠${NC} Backend deployed but health check failed"
        fi
        return 0
    else
        echo -e "${RED}✗${NC} Backend NOT deployed to Cloud Run"
        return 1
    fi
}

echo "===================================================="
echo "1. Checking CLI Tools..."
echo "===================================================="
GCLOUD_OK=0
FIREBASE_OK=0
check_command "gcloud" || GCLOUD_OK=1
check_command "firebase" || FIREBASE_OK=1
check_command "npm" || echo -e "${YELLOW}⚠${NC} npm not found (needed for frontend)"
check_command "docker" || echo -e "${YELLOW}⚠${NC} docker not found (optional)"
echo ""

if [ $GCLOUD_OK -ne 0 ]; then
    echo -e "${RED}ERROR:${NC} gcloud CLI is required but not installed"
    echo "Install: https://cloud.google.com/sdk/docs/install"
    echo ""
fi

if [ $FIREBASE_OK -ne 0 ]; then
    echo -e "${RED}ERROR:${NC} firebase CLI is required but not installed"
    echo "Install: npm install -g firebase-tools"
    echo ""
fi

if [ $GCLOUD_OK -ne 0 ] || [ $FIREBASE_OK -ne 0 ]; then
    echo "Please install missing tools and run this script again."
    exit 1
fi

echo "===================================================="
echo "2. Checking Authentication..."
echo "===================================================="
check_gcloud_auth || {
    echo -e "${YELLOW}Action:${NC} Run 'gcloud auth login'"
    echo ""
}

# Check current project
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ "$CURRENT_PROJECT" = "$PROJECT_ID" ]; then
    echo -e "${GREEN}✓${NC} Current project is set to: $PROJECT_ID"
else
    echo -e "${YELLOW}⚠${NC} Current project is: $CURRENT_PROJECT (expected: $PROJECT_ID)"
    echo -e "${YELLOW}Action:${NC} Run 'gcloud config set project $PROJECT_ID'"
fi
echo ""

echo "===================================================="
echo "3. Checking Google Cloud APIs..."
echo "===================================================="
APIS=(
    "run.googleapis.com"
    "cloudbuild.googleapis.com"
    "containerregistry.googleapis.com"
    "secretmanager.googleapis.com"
    "logging.googleapis.com"
    "artifactregistry.googleapis.com"
)

MISSING_APIS=()
for API in "${APIS[@]}"; do
    check_api "$API" || MISSING_APIS+=("$API")
done

if [ ${#MISSING_APIS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Action:${NC} Enable missing APIs with:"
    for API in "${MISSING_APIS[@]}"; do
        echo "  gcloud services enable $API --project=$PROJECT_ID"
    done
fi
echo ""

echo "===================================================="
echo "4. Checking Service Account Permissions..."
echo "===================================================="
REQUIRED_ROLES=(
    "roles/logging.viewer"
    "roles/logging.logWriter"
    "roles/run.admin"
    "roles/iam.serviceAccountUser"
    "roles/secretmanager.secretAccessor"
    "roles/firebase.admin"
)

MISSING_ROLES=()
for ROLE in "${REQUIRED_ROLES[@]}"; do
    check_iam_role "serviceAccount:$SERVICE_ACCOUNT" "$ROLE" || MISSING_ROLES+=("$ROLE")
done

if [ ${#MISSING_ROLES[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Action:${NC} Add missing roles with:"
    for ROLE in "${MISSING_ROLES[@]}"; do
        echo "  gcloud projects add-iam-policy-binding $PROJECT_ID \\"
        echo "    --member=\"serviceAccount:$SERVICE_ACCOUNT\" \\"
        echo "    --role=\"$ROLE\""
    done
fi
echo ""

echo "===================================================="
echo "5. Checking Secrets..."
echo "===================================================="
check_secret "firebase-admin-key" || {
    echo -e "${YELLOW}Action:${NC} Create secret with:"
    echo "  cd scripts && ./setup-secrets.sh"
}
echo ""

echo "===================================================="
echo "6. Checking Backend Deployment..."
echo "===================================================="
check_cloud_run_service || {
    echo -e "${YELLOW}Action:${NC} Deploy backend with:"
    echo "  cd scripts && ./deploy.sh"
    echo "  (Select option 1: Backend only)"
}
echo ""

echo "===================================================="
echo "7. Checking Frontend Configuration..."
echo "===================================================="
FRONTEND_CONFIG="../frontend/src/firebaseConfig.js"
if [ -f "$FRONTEND_CONFIG" ]; then
    if grep -q "YOUR_API_KEY" "$FRONTEND_CONFIG" || grep -q "YOUR_SENDER_ID" "$FRONTEND_CONFIG"; then
        echo -e "${RED}✗${NC} Frontend config has placeholder values"
        echo -e "${YELLOW}Action:${NC} Update $FRONTEND_CONFIG with actual Firebase config"
        echo "  Get from: https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
    else
        echo -e "${GREEN}✓${NC} Frontend config appears to be set"
    fi
else
    echo -e "${RED}✗${NC} Frontend config file not found"
fi
echo ""

echo "===================================================="
echo "8. Checking Firebase Hosting..."
echo "===================================================="
# Check if frontend is deployed (this is harder to check programmatically)
echo "Checking if frontend is deployed..."
if curl -s -f -m 5 "https://$PROJECT_ID.web.app" &> /dev/null; then
    echo -e "${GREEN}✓${NC} Frontend is deployed at: https://$PROJECT_ID.web.app"
else
    echo -e "${RED}✗${NC} Frontend NOT deployed or not accessible"
    echo -e "${YELLOW}Action:${NC} Deploy frontend with:"
    echo "  cd frontend && npm run build && firebase deploy --only hosting"
fi
echo ""

echo "===================================================="
echo "9. Summary & Next Steps"
echo "===================================================="
echo ""
echo "📋 Recommended actions:"
echo ""
echo "If you see RED (✗) items above, follow these steps:"
echo ""
echo "1. Enable missing APIs (if any)"
echo "2. Add missing IAM roles (if any)"
echo "3. Create Firebase Web App and get config"
echo "   → https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
echo "4. Update frontend/src/firebaseConfig.js with the config"
echo "5. Create Service Account JSON key"
echo "   → https://console.cloud.google.com/iam-admin/serviceaccounts?project=$PROJECT_ID"
echo "6. Run: cd scripts && ./setup-secrets.sh"
echo "7. Run: cd scripts && ./deploy.sh (select option 3: Both)"
echo "8. Test: https://$PROJECT_ID.web.app"
echo ""
echo "For detailed instructions, see: COMPLETE_SETUP_GUIDE_HEBREW.md"
echo ""
echo "===================================================="
echo "Diagnosis complete!"
echo "===================================================="
