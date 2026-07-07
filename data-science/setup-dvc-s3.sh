#!/bin/bash
# DVC + S3 Quick Setup Script
# Run this from data-science/ after Terraform apply

set -e

echo "🚀 DVC + S3 Setup"
echo "=================="

# Step 1: Get bucket name from Terraform
echo "📦 Retrieving DVC bucket name from Terraform..."
cd ../infrastructure
BUCKET_NAME=$(terraform output -raw dvc_bucket_name)
DVC_IRSA_ROLE=$(terraform output -raw dvc_irsa_role_arn)
echo "✓ Bucket: $BUCKET_NAME"
echo "✓ IRSA Role: $DVC_IRSA_ROLE"

# Step 2: Go back to data-science
cd ../data-science
echo ""
echo "📝 Configuring DVC remote..."

# Step 3: Configure DVC remote
dvc remote modify s3remote url "s3://$BUCKET_NAME"
dvc config core.remote s3remote
echo "✓ DVC configured to use S3"

# Step 4: Verify AWS credentials
echo ""
echo "🔐 Checking AWS credentials..."
if aws sts get-caller-identity &>/dev/null; then
    echo "✓ AWS credentials found"
    AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
    echo "  Account: $AWS_ACCOUNT"
else
    echo "⚠️  No AWS credentials found. Run 'aws configure' first."
    exit 1
fi

# Step 5: Push existing data
echo ""
echo "📤 Pushing data to S3..."
if dvc push; then
    echo "✓ Data pushed successfully"
else
    echo "⚠️  No data to push yet (expected on first run)"
fi

# Step 6: Display summary
echo ""
echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo "1. Verify .dvc/config:"
echo "   cat .dvc/config"
echo ""
echo "2. Add your CSV with DVC:"
echo "   dvc add data/raw/your-file.csv"
echo ""
echo "3. Commit metadata to Git:"
echo "   git add data/raw/your-file.csv.dvc .gitignore"
echo "   git commit -m 'Track data with DVC'"
echo ""
echo "4. Push data to S3:"
echo "   dvc push"
echo ""
echo "5. Run the pipeline:"
echo "   export MLFLOW_TRACKING_URI=http://mlflow.local"
echo "   dvc repro"
echo ""
echo "For more details, see: DVC_SETUP.md"
