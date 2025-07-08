#!/bin/bash

# Amazon Q Business Sample Data Setup Script
# This script creates an S3 bucket and uploads sample documents for the enterprise template

set -e  # Exit on any error

# Configuration
BUCKET_NAME=""
REGION="us-east-1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DATA_DIR="$SCRIPT_DIR/sample-data"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first:"
        echo "  https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI is installed and configured"
}

# Function to validate bucket name
validate_bucket_name() {
    if [[ -z "$BUCKET_NAME" ]]; then
        print_error "Bucket name is required"
        echo "Usage: $0 <bucket-name> [region]"
        echo "Example: $0 my-company-qbusiness-docs us-east-1"
        exit 1
    fi
    
    # Check bucket name format
    if [[ ! "$BUCKET_NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]] || [[ ${#BUCKET_NAME} -lt 3 ]] || [[ ${#BUCKET_NAME} -gt 63 ]]; then
        print_error "Invalid bucket name format"
        echo "Bucket names must:"
        echo "  - Be 3-63 characters long"
        echo "  - Start and end with lowercase letter or number"
        echo "  - Contain only lowercase letters, numbers, and hyphens"
        exit 1
    fi
}

# Function to create S3 bucket
create_bucket() {
    print_status "Creating S3 bucket: $BUCKET_NAME in region: $REGION"
    
    # Check if bucket already exists
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        print_warning "Bucket $BUCKET_NAME already exists"
        return 0
    fi
    
    # Create bucket
    if [[ "$REGION" == "us-east-1" ]]; then
        # us-east-1 doesn't need LocationConstraint
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    
    print_success "Bucket created successfully"
}

# Function to configure bucket settings
configure_bucket() {
    print_status "Configuring bucket settings..."
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    # Set bucket encryption
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    },
                    "BucketKeyEnabled": true
                }
            ]
        }'
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    print_success "Bucket configured with versioning, encryption, and public access blocked"
}

# Function to add metadata to files
add_metadata_to_file() {
    local file_path="$1"
    local s3_key="$2"
    local department=""
    local document_type=""
    local confidentiality=""
    
    # Extract metadata from file path and content
    case "$s3_key" in
        policies/*)
            department="Human Resources"
            document_type="Policy"
            confidentiality="Internal"
            ;;
        procedures/*)
            department="Information Technology"
            document_type="Procedure"
            confidentiality="Internal"
            ;;
        manuals/*)
            department="Engineering"
            document_type="Manual"
            confidentiality="Internal"
            ;;
        faqs/*)
            department="Customer Support"
            document_type="FAQ"
            confidentiality="Public"
            ;;
        *)
            department="General"
            document_type="Document"
            confidentiality="Internal"
            ;;
    esac
    
    # Upload file with metadata
    aws s3 cp "$file_path" "s3://$BUCKET_NAME/$s3_key" \
        --metadata "department=$department,document_type=$document_type,confidentiality=$confidentiality" \
        --content-type "text/markdown"
}

# Function to upload sample data
upload_sample_data() {
    print_status "Uploading sample data files..."
    
    if [[ ! -d "$SAMPLE_DATA_DIR" ]]; then
        print_error "Sample data directory not found: $SAMPLE_DATA_DIR"
        exit 1
    fi
    
    local file_count=0
    
    # Upload all markdown files with appropriate metadata
    while IFS= read -r -d '' file; do
        # Get relative path from sample-data directory
        local rel_path="${file#$SAMPLE_DATA_DIR/}"
        
        print_status "Uploading: $rel_path"
        add_metadata_to_file "$file" "$rel_path"
        
        ((file_count++))
    done < <(find "$SAMPLE_DATA_DIR" -name "*.md" -type f -print0)
    
    print_success "Uploaded $file_count sample documents"
}

# Function to create additional sample files
create_additional_samples() {
    print_status "Creating additional sample files..."
    
    # Create a simple text file
    local temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
Company Overview

Document Type: Overview
Department: Executive
Confidentiality: Public
Last Modified: 2024-01-01

Our company is a leading technology firm specializing in innovative software solutions.
We serve clients across various industries with cutting-edge products and services.

Mission: To deliver exceptional technology solutions that drive business success.
Vision: To be the most trusted technology partner for businesses worldwide.
Values: Innovation, Integrity, Excellence, Collaboration

Founded: 2010
Headquarters: San Francisco, CA
Employees: 500+
Global Offices: 5
EOF
    
    aws s3 cp "$temp_file" "s3://$BUCKET_NAME/company/overview.txt" \
        --metadata "department=Executive,document_type=Overview,confidentiality=Public" \
        --content-type "text/plain"
    
    rm "$temp_file"
    
    # Create a sample PDF placeholder (text file with PDF extension for demo)
    local pdf_temp=$(mktemp)
    cat > "$pdf_temp" << 'EOF'
This is a placeholder for a PDF document.
In a real scenario, this would be an actual PDF file.

Document: Annual Report 2023
Department: Finance
Type: Report
Confidentiality: Confidential
EOF
    
    aws s3 cp "$pdf_temp" "s3://$BUCKET_NAME/reports/annual-report-2023.pdf" \
        --metadata "department=Finance,document_type=Report,confidentiality=Confidential" \
        --content-type "application/pdf"
    
    rm "$pdf_temp"
    
    print_success "Created additional sample files"
}

# Function to verify upload
verify_upload() {
    print_status "Verifying uploaded files..."
    
    local file_count=$(aws s3 ls "s3://$BUCKET_NAME" --recursive | wc -l)
    
    if [[ $file_count -gt 0 ]]; then
        print_success "Successfully uploaded $file_count files to S3 bucket"
        
        echo ""
        echo "Files in bucket:"
        aws s3 ls "s3://$BUCKET_NAME" --recursive --human-readable
        
        echo ""
        print_success "Sample data setup complete!"
        echo ""
        echo "Next steps:"
        echo "1. Use bucket name '$BUCKET_NAME' in your QBusiness Enterprise template"
        echo "2. Deploy the CloudFormation template"
        echo "3. Wait for the data source sync to complete"
        echo "4. Test the Q Business application with sample queries"
        echo ""
        echo "Sample queries to try:"
        echo "- 'What is our expense policy for meals?'"
        echo "- 'How do I reset my password?'"
        echo "- 'What are the security procedures for new employees?'"
        echo "- 'What benefits does the company offer?'"
        
    else
        print_error "No files found in bucket after upload"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Amazon Q Business Sample Data Setup"
    echo ""
    echo "Usage: $0 <bucket-name> [region]"
    echo ""
    echo "Arguments:"
    echo "  bucket-name    Name for the S3 bucket (required)"
    echo "  region         AWS region (optional, default: us-east-1)"
    echo ""
    echo "Examples:"
    echo "  $0 my-company-qbusiness-docs"
    echo "  $0 my-company-qbusiness-docs us-west-2"
    echo ""
    echo "The script will:"
    echo "  1. Create an S3 bucket with proper configuration"
    echo "  2. Upload sample company documents with metadata"
    echo "  3. Configure bucket for Q Business data source integration"
    echo ""
}

# Main execution
main() {
    echo "========================================="
    echo "Amazon Q Business Sample Data Setup"
    echo "========================================="
    echo ""
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    BUCKET_NAME="$1"
    if [[ -n "$2" ]]; then
        REGION="$2"
    fi
    
    # Validate inputs
    validate_bucket_name
    check_aws_cli
    
    # Execute setup steps
    create_bucket
    configure_bucket
    upload_sample_data
    create_additional_samples
    verify_upload
}

# Run main function with all arguments
main "$@"
