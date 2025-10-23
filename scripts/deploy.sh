#!/bin/bash

# Comprehensive Deployment Script for OnBordA
# This script automates the deployment process

set -e  # Exit on error

PROJECT_ID="onborda"
REGION="us-central1"
SERVICE_NAME="saas-backend-service"

echo "🚀 OnBordA Deployment Script"
echo "============================="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed"
    echo "Installing Firebase CLI..."
    npm install -g firebase-tools
fi

# Set project
echo "📌 Setting project to: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Menu
echo ""
echo "What would you like to deploy?"
echo "1. Backend only (Cloud Run)"
echo "2. Frontend only (Firebase Hosting)"
echo "3. Both Backend and Frontend"
echo "4. Just build (no deploy)"
echo ""
read -p "Enter your choice (1-4): " choice

# Function to deploy backend
deploy_backend() {
    echo ""
    echo "🔨 Building and deploying Backend..."
    echo "-----------------------------------"
    
    cd "$(dirname "$0")/.."
    
    # Submit build
    echo "📦 Submitting build to Cloud Build..."
    gcloud builds submit --config=cloudbuild.yaml --project=$PROJECT_ID
    
    # Get service URL
    echo ""
    echo "🌐 Getting Cloud Run service URL..."
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format="value(status.url)")
    
    echo ""
    echo "✅ Backend deployed successfully!"
    echo "   URL: $SERVICE_URL"
    echo ""
    echo "⚠️  Remember to update frontend/src/firebaseConfig.js with this URL:"
    echo "   export const API_URL = \"$SERVICE_URL\";"
    echo ""
    
    # Test health endpoint
    echo "🏥 Testing health endpoint..."
    if curl -s "${SERVICE_URL}/api/health" | grep -q "healthy"; then
        echo "✅ Health check passed!"
    else
        echo "⚠️  Health check failed. Please check logs."
    fi
}

# Function to deploy frontend
deploy_frontend() {
    echo ""
    echo "🎨 Building and deploying Frontend..."
    echo "------------------------------------"
    
    cd "$(dirname "$0")/../frontend"
    
    # Install dependencies
    echo "📦 Installing dependencies..."
    npm install
    
    # Build
    echo "🔨 Building frontend..."
    npm run build
    
    # Deploy
    echo "🚀 Deploying to Firebase Hosting..."
    firebase deploy --only hosting --project $PROJECT_ID
    
    echo ""
    echo "✅ Frontend deployed successfully!"
    echo "   URL: https://$PROJECT_ID.web.app"
    echo ""
}

# Function to just build
just_build() {
    echo ""
    echo "🔨 Building both Backend and Frontend..."
    echo "---------------------------------------"
    
    # Build backend Docker image locally
    echo "📦 Building Backend Docker image..."
    cd "$(dirname "$0")/../backend"
    docker build -t onborda-backend:local .
    
    # Build frontend
    echo "📦 Building Frontend..."
    cd "$(dirname "$0")/../frontend"
    npm install
    npm run build
    
    echo ""
    echo "✅ Build completed successfully!"
    echo "   Backend image: onborda-backend:local"
    echo "   Frontend: frontend/dist/"
    echo ""
}

# Execute based on choice
case $choice in
    1)
        deploy_backend
        ;;
    2)
        deploy_frontend
        ;;
    3)
        deploy_backend
        deploy_frontend
        ;;
    4)
        just_build
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "🎉 Deployment process completed!"
echo ""
