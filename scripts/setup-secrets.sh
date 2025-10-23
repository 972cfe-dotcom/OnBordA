#!/bin/bash

# Setup Secrets for OnBordA Project
# This script helps you setup Secret Manager for the backend deployment

set -e  # Exit on error

PROJECT_ID="onborda"
REGION="us-central1"
SERVICE_NAME="saas-backend-service"
SERVICE_ACCOUNT="sa-backend-firebase@onborda.iam.gserviceaccount.com"

echo "🚀 OnBordA Secret Manager Setup"
echo "================================"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if logged in
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo "❌ Not logged in to gcloud"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Set project
echo "📌 Setting project to: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo ""
echo "🔧 Enabling required APIs..."
gcloud services enable secretmanager.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Check if service account key file exists
echo ""
echo "🔑 Service Account Key Setup"
echo "----------------------------"
read -p "Do you have the Service Account JSON key file? (y/n): " has_key

if [ "$has_key" != "y" ]; then
    echo ""
    echo "⚠️  You need to download the Service Account key:"
    echo "1. Go to: https://console.cloud.google.com/iam-admin/serviceaccounts?project=$PROJECT_ID"
    echo "2. Find: $SERVICE_ACCOUNT"
    echo "3. Click Actions (⋮) → Manage keys"
    echo "4. Add Key → Create new key → JSON"
    echo "5. Download and save the file"
    echo ""
    echo "After downloading, run this script again."
    exit 0
fi

# Ask for key file path
echo ""
read -p "Enter the path to your Service Account JSON key file: " key_file_path

if [ ! -f "$key_file_path" ]; then
    echo "❌ File not found: $key_file_path"
    exit 1
fi

# Create secret
echo ""
echo "📝 Creating secret in Secret Manager..."

# Check if secret already exists
if gcloud secrets describe firebase-admin-key --project=$PROJECT_ID &> /dev/null; then
    echo "⚠️  Secret 'firebase-admin-key' already exists"
    read -p "Do you want to add a new version? (y/n): " add_version
    
    if [ "$add_version" = "y" ]; then
        gcloud secrets versions add firebase-admin-key \
            --data-file="$key_file_path" \
            --project=$PROJECT_ID
        echo "✅ New secret version added"
    fi
else
    gcloud secrets create firebase-admin-key \
        --data-file="$key_file_path" \
        --project=$PROJECT_ID
    echo "✅ Secret created"
fi

# Grant Cloud Build access to secret
echo ""
echo "🔐 Granting Cloud Build access to secret..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

gcloud secrets add-iam-policy-binding firebase-admin-key \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor" \
    --project=$PROJECT_ID

echo "✅ Cloud Build can now access the secret"

# Extract private key for environment variable
echo ""
echo "📋 Extracting Private Key for Cloud Run deployment..."
PRIVATE_KEY=$(cat "$key_file_path" | jq -r '.private_key')

# Update backend .env file
ENV_FILE="../backend/.env"
if [ -f "$ENV_FILE" ]; then
    echo "📝 Updating backend/.env file..."
    # Escape special characters for sed
    ESCAPED_KEY=$(printf '%s\n' "$PRIVATE_KEY" | sed -e 's/[]\/$*.^[]/\\&/g')
    sed -i "s|FIREBASE_PRIVATE_KEY=\"YOUR_PRIVATE_KEY_HERE\"|FIREBASE_PRIVATE_KEY=\"$ESCAPED_KEY\"|g" "$ENV_FILE"
    echo "✅ Backend .env updated"
else
    echo "⚠️  Backend .env file not found at $ENV_FILE"
fi

echo ""
echo "✅ Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Run: gcloud builds submit --config=cloudbuild.yaml --project=$PROJECT_ID"
echo "2. Or push to GitHub to trigger automatic deployment"
echo ""
