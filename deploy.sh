#!/bin/bash

# Open WebUI AKS Deployment Script
# This script helps you deploy Open WebUI on Azure Kubernetes Service

set -e

echo "=========================================="
echo "Open WebUI AKS Deployment Helper"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check prerequisites
echo "Checking prerequisites..."

# Check if terraform is installed
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | grep -o '"version":"[^"]*' | cut -d'"' -f4)
    print_success "Terraform is installed (version: $TERRAFORM_VERSION)"
else
    print_error "Terraform is not installed. Please install Terraform >= 1.14.0"
    exit 1
fi

# Check if az CLI is installed
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --output json | grep -o '"azure-cli": "[^"]*' | cut -d'"' -f4)
    print_success "Azure CLI is installed (version: $AZ_VERSION)"
else
    print_error "Azure CLI is not installed. Please install Azure CLI"
    exit 1
fi

# Check if kubectl is installed
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | grep -o 'v[0-9.]*')
    print_success "kubectl is installed (version: $KUBECTL_VERSION)"
else
    print_error "kubectl is not installed. Please install kubectl"
    exit 1
fi

echo ""
echo "=========================================="
echo "Configuration Check"
echo "=========================================="

# Check if user is logged in to Azure
if az account show &> /dev/null; then
    SUBSCRIPTION=$(az account show --query name -o tsv)
    print_success "Logged in to Azure (Subscription: $SUBSCRIPTION)"
else
    print_error "Not logged in to Azure. Please run: az login"
    exit 1
fi

# Check if locals.tf has been configured
if grep -q "YOUR_AZURE_SUBSCRIPTION_ID" tf_files/2-locals.tf; then
    print_warning "You need to configure tf_files/2-locals.tf with your values"
    echo "  Please update the following:"
    echo "    - subscription_id"
    echo "    - cf_account_id"
    echo "    - cf_zone_id"
    echo "    - cf_zone_name"
    echo "    - TAG_OWNER"
    echo "    - TAG_CREATED_BY"
    exit 1
else
    print_success "Terraform locals.tf appears to be configured"
fi

# Check if provider.tf has been configured
if grep -q "YOUR_AZURE_TENANT_ID" tf_files/0-provider.tf; then
    print_warning "You need to configure tf_files/0-provider.tf with your tenant ID"
    exit 1
else
    print_success "Terraform provider.tf appears to be configured"
fi

echo ""
echo "=========================================="
echo "Deployment Options"
echo "=========================================="
echo "1) Deploy infrastructure only (Terraform)"
echo "2) Deploy Kubernetes resources only"
echo "3) Full deployment (Terraform + Kubernetes)"
echo "4) Destroy infrastructure"
echo "5) Exit"
echo ""

read -p "Enter your choice [1-5]: " choice

case $choice in
    1)
        echo ""
        print_info "Deploying infrastructure with Terraform..."
        cd tf_files
        terraform init
        terraform plan
        read -p "Do you want to apply this plan? (yes/no): " confirm
        if [ "$confirm" == "yes" ]; then
            terraform apply
            print_success "Infrastructure deployment completed!"
        else
            print_warning "Deployment cancelled"
        fi
        ;;
    2)
        echo ""
        print_info "Deploying Kubernetes resources..."
        cd yaml_files
        
        # Check if ConfigMap has been configured
        if grep -q "yourdomain.com" 5-config-map.yaml; then
            print_warning "You need to configure yaml_files/5-config-map.yaml with your domain"
            exit 1
        fi
        
        # Check if SecretStore has been configured
        if grep -q "YOUR_MANAGED_IDENTITY_CLIENT_ID" 3-secret-store.yaml; then
            print_warning "You need to configure yaml_files/3-secret-store.yaml with your managed identity"
            exit 1
        fi
        
        echo "Applying Kubernetes manifests..."
        kubectl apply -f 0-namespace.yaml
        kubectl apply -f 1-ollama-pvc.yaml
        kubectl apply -f 2-open-webui-pvc.yaml
        kubectl apply -f 3-secret-store.yaml
        kubectl apply -f 4-external-secret.yaml
        kubectl apply -f 5-config-map.yaml
        kubectl apply -f 6-ollama-deployment.yaml
        kubectl apply -f 7-open-webui-deployment.yaml
        kubectl apply -f 8-ollama-svc.yaml
        kubectl apply -f 9-open-webui-svc.yaml
        kubectl apply -f 10-cf-tunnel.yaml
        
        print_success "Kubernetes resources deployed!"
        echo ""
        print_info "Checking pod status..."
        kubectl get pods -n open-webui
        ;;
    3)
        echo ""
        print_info "Starting full deployment..."
        
        # Deploy Terraform
        print_info "Step 1: Deploying infrastructure..."
        cd tf_files
        terraform init
        terraform plan
        read -p "Do you want to apply this Terraform plan? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_warning "Deployment cancelled"
            exit 0
        fi
        terraform apply
        cd ..
        
        # Deploy Kubernetes
        print_info "Step 2: Deploying Kubernetes resources..."
        cd yaml_files
        kubectl apply -f .
        cd ..
        
        print_success "Full deployment completed!"
        echo ""
        print_info "Checking deployment status..."
        kubectl get all -n open-webui
        ;;
    4)
        echo ""
        print_warning "This will destroy all infrastructure!"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        if [ "$confirm" == "yes" ]; then
            cd tf_files
            terraform destroy
            print_success "Infrastructure destroyed"
        else
            print_warning "Destroy cancelled"
        fi
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
print_success "Script completed successfully!"
echo "=========================================="
