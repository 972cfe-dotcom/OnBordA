#!/bin/bash

# OnBordA - Quick Fix Script for Permissions
# Run this after ensuring gcloud is authenticated

set -e

PROJECT_ID="onborda"
SERVICE_ACCOUNT="sa-backend-firebase@onborda.iam.gserviceaccount.com"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}   OnBordA - Quick Permissions Fix${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${RED}ERROR:${NC} Please authenticate first with 'gcloud auth login'"
    exit 1
fi

# Set project
echo "Setting project to: $PROJECT_ID"
gcloud config set project $PROJECT_ID
echo ""

echo "===================================================="
echo "Step 1: Enabling Required APIs..."
echo "===================================================="
APIS=(
    "run.googleapis.com"
    "cloudbuild.googleapis.com"
    "containerregistry.googleapis.com"
    "secretmanager.googleapis.com"
    "logging.googleapis.com"
    "artifactregistry.googleapis.com"
    "firebase.googleapis.com"
)

for API in "${APIS[@]}"; do
    echo -n "Enabling $API... "
    if gcloud services enable $API --project=$PROJECT_ID 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
done
echo ""

echo "===================================================="
echo "Step 2: Adding IAM Roles to Service Account..."
echo "===================================================="
ROLES=(
    "roles/logging.viewer"
    "roles/logging.logWriter"
    "roles/run.admin"
    "roles/iam.serviceAccountUser"
    "roles/secretmanager.secretAccessor"
    "roles/firebase.admin"
    "roles/cloudbuild.builds.builder"
)

for ROLE in "${ROLES[@]}"; do
    echo -n "Adding $ROLE... "
    if gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="$ROLE" \
        --condition=None \
        &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC} (might already exist)"
    fi
done
echo ""

echo "===================================================="
echo "Step 3: Adding IAM Roles to Cloud Build SA..."
echo "===================================================="
echo "Getting Cloud Build service account..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
CLOUD_BUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

echo "Cloud Build SA: $CLOUD_BUILD_SA"

CB_ROLES=(
    "roles/run.admin"
    "roles/iam.serviceAccountUser"
    "roles/logging.logWriter"
    "roles/secretmanager.secretAccessor"
)

for ROLE in "${CB_ROLES[@]}"; do
    echo -n "Adding $ROLE to Cloud Build SA... "
    if gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$CLOUD_BUILD_SA" \
        --role="$ROLE" \
        --condition=None \
        &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC} (might already exist)"
    fi
done
echo ""

echo "===================================================="
echo "Step 4: Verifying Setup..."
echo "===================================================="

# Verify APIs
echo "Checking enabled APIs..."
ENABLED_COUNT=0
for API in "${APIS[@]}"; do
    if gcloud services list --enabled --project=$PROJECT_ID 2>/dev/null | grep -q "$API"; then
        ENABLED_COUNT=$((ENABLED_COUNT + 1))
    fi
done
echo -e "Enabled APIs: $ENABLED_COUNT/${#APIS[@]}"

# Verify SA roles
echo "Checking Service Account roles..."
ROLE_COUNT=$(gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:$SERVICE_ACCOUNT" \
    --format="value(bindings.role)" 2>/dev/null | wc -l)
echo -e "Service Account has $ROLE_COUNT roles"
echo ""

echo "===================================================="
echo -e "${GREEN}✓ Permissions setup complete!${NC}"
echo "===================================================="
echo ""
echo "Next steps:"
echo "1. Create Firebase Web App config:"
echo "   https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
echo ""
echo "2. Create Service Account JSON key:"
echo "   https://console.cloud.google.com/iam-admin/serviceaccounts?project=$PROJECT_ID"
echo ""
echo "3. Run setup-secrets.sh to configure secrets"
echo "4. Run deploy.sh to deploy the application"
echo ""
echo "For detailed guide, see: COMPLETE_SETUP_GUIDE_HEBREW.md"
