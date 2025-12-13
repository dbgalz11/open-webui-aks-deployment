# Open WebUI AKS Deployment

A complete Infrastructure as Code (IaC) solution for deploying [Open WebUI](https://github.com/open-webui/open-webui) and [Ollama](https://ollama.ai/) on Azure Kubernetes Service (AKS) with secure Azure integration, external secret management, and Cloudflare Tunnel for secure external access.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

This repository provides a production-ready deployment of Open WebUI with Ollama on Azure Kubernetes Service. It automates the complete infrastructure provisioning and application deployment process using Terraform and Kubernetes manifests.

**What is Open WebUI?**
Open WebUI is an extensible, feature-rich, and user-friendly self-hosted WebUI designed to operate entirely offline. It supports various LLM runners, including Ollama and OpenAI-compatible APIs.

**What is Ollama?**
Ollama allows you to run large language models locally, providing privacy and control over your AI workloads.

## 🏗️ Architecture

```mermaid
graph TB
    subgraph Cloudflare["Cloudflare"]
        DNS[DNS Record<br/>open-webui.yourdomain.com]
        Tunnel[Zero Trust Tunnel]
    end
    
    subgraph Azure["Azure Cloud"]
        subgraph AKS["Azure Kubernetes Service"]
            subgraph NS["Namespace: open-webui"]
                WebUI[Open WebUI<br/>Port 8080<br/>3 replicas]
                Ollama[Ollama<br/>Port 11434]
                WebUIPVC[Azure Files PVC<br/>File Storage]
                OllamaPVC[Azure Disk PVC<br/>Model Storage]
                ESO[External Secrets Operator]
                Reloader[Stakater Reloader]
                CFTunnel[Cloudflared]
                NetShoot[NetShoot Pod<br/>Debug Tool]
                PSQLClient[PostgreSQL Client<br/>Debug Tool]
            end
        end
        
        subgraph AzureResources["Azure Resources"]
            KV[Key Vault]
            UAI[User-Assigned Identity<br/>+RBAC Role]
            AppReg[App Registration<br/>OAuth 2.0]
            VMSS[AKS Node Pool VMSS]
            Storage[Azure Storage<br/>Files + Private Endpoint]
            PostgreSQL[PostgreSQL Flexible<br/>Database + Private Endpoint]
        end
    end
    
    Users[Users] -->|HTTPS| DNS
    DNS --> Tunnel
    Tunnel --> CFTunnel
    CFTunnel --> WebUI
    WebUI <--> Ollama
    WebUI -->|File Storage| WebUIPVC
    WebUI -->|Database| PostgreSQL
    Ollama --> OllamaPVC
    WebUIPVC -.->|SMB| Storage
    ESO -->|Sync| WebUI
    ESO -->|Sync| CFTunnel
    Reloader -.->|Watch| WebUI
    Reloader -.->|Watch| CFTunnel
    UAI -->|Attached| VMSS
    VMSS -->|Identity| ESO
    ESO -->|Auth| KV
    UAI -->|RBAC| KV
    WebUI -->|Login| AppReg
    NetShoot -.->|Network Debug| WebUI
    PSQLClient -.->|DB Debug| PostgreSQL
```

### Component Flow:

1. **Terraform** provisions Azure resources (AKS, PostgreSQL Flexible Server, Azure Storage with Private Endpoint, Key Vault, Managed Identity, App Registration)
2. **User-Assigned Managed Identity (UAI)** is assigned **Key Vault Secrets Officer** role and attached to the AKS node pool
3. **PostgreSQL Flexible Server** serves as the external database for Open WebUI (replaces built-in SQLite) with private endpoint connectivity
4. **Azure Files** provides shared file storage for uploads and cache with SMB protocol and private endpoint
5. **Kubernetes manifests** deploy Open WebUI (3 replicas) and Ollama with persistent storage
6. **External Secrets Operator** uses the UAI to sync secrets  from Azure Key Vault to Kubernetes
7. **Stakater Reloader** watches for secret/configmap changes and automatically restarts affected pods
8. **Cloudflare Tunnel** provides secure external access without exposing public IPs
9. **Entra ID (Azure AD) OAuth** enables secure authentication with Microsoft accounts
10. **Debug pods** (NetShoot and PostgreSQL Client) available for troubleshooting network and database connectivity

### Container Image Management

This deployment uses container images stored in your organization's Azure Container Registry (ACR) for better control, security, and compliance:

**Image Preparation Process:**

1. **Pull official images from Docker Hub:**
   ```bash
   docker pull ollama/ollama:latest
   docker pull ghcr.io/open-webui/open-webui:main
   ```

2. **Retag images for your ACR:**
   ```bash
   docker tag ollama/ollama:latest yourorg.azurecr.io/ollama:latest
   docker tag ghcr.io/open-webui/open-webui:main yourorg.azurecr.io/open-webui:main
   ```

3. **Authenticate to ACR:**
   ```bash
   az acr login --name yourorg
   ```

4. **Push images to your ACR:**
   ```bash
   docker push yourorg.azurecr.io/ollama:latest
   docker push yourorg.azurecr.io/open-webui:main
   ```

5. **Update Kubernetes deployments** to use ACR images (already configured in `yaml_files/6-ollama-deployment.yaml` and `yaml_files/7-open-webui-deployment.yaml`)

**Benefits of using ACR:**
- ✅ **Image scanning** for vulnerabilities before deployment
- ✅ **Corporate compliance** with approved container registries
- ✅ **Better performance** when pulling images within Azure network
- ✅ **Version control** and image lifecycle management
- ✅ **Network security** with private endpoints and firewall rules
- ✅ **Image caching** reduces external dependencies

## ✨ Features

- **🚀 Automated Infrastructure Provisioning**: Complete Azure resource setup via Terraform
- **�️ PostgreSQL Database**: Azure Database for PostgreSQL Flexible Server with private endpoint (replaces SQLite)
- **📁 Azure Files Storage**: Shared file storage with SMB protocol and private endpoint for uploads and cache
- **�🔐 Secure Secret Management**: Azure Key Vault with User-Assigned Managed Identity (no credentials in code)
- **🔑 RBAC-Based Access**: UAI with Key Vault Secrets Officer role assigned to AKS node pool
- **🔄 Automatic Secret Rotation**: Stakater Reloader automatically restarts pods when secrets are updated
- **🌐 Cloudflare Tunnel Integration**: Zero-trust network access without public IP exposure
- **🔑 Entra ID (Azure AD) SSO**: Microsoft OAuth 2.0/OIDC authentication for secure user access
- **💾 Persistent Storage**: Azure Managed Disks for Ollama models, Azure Files for shared data
- **⚡ High Availability**: 3 replicas of Open WebUI with RollingUpdate strategy
- **🎯 Production-Ready**: Includes health checks, resource limits, and high availability configurations
- **🔧 Debugging Tools**: Includes NetShoot and PostgreSQL client pods for troubleshooting
- **🔐 Private Networking**: PostgreSQL and Storage Account accessible only via private endpoints
- **🔧 Modular & Extensible**: Easy to customize for different environments and requirements

## 📦 Prerequisites

Before you begin, ensure you have the following:

### Required Tools

- **Terraform** >= 1.14.0 ([Installation Guide](https://developer.hashicorp.com/terraform/downloads))
- **Azure CLI** >= 2.50.0 ([Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- **kubectl** >= 1.28.0 ([Installation Guide](https://kubernetes.io/docs/tasks/tools/))
- **Docker** (for pulling and pushing container images) ([Installation Guide](https://docs.docker.com/get-docker/))
- **Cloudflare Account** with API token access

### Azure Resources

- Active Azure subscription
- **Azure Container Registry (ACR)** for storing container images
- Permissions to create:
  - Resource Groups
  - AKS Clusters
  - Azure Database for PostgreSQL Flexible Server
  - Storage Accounts (with Azure Files)
  - Private Endpoints
  - Private DNS Zones
  - Virtual Networks and Subnets
  - Key Vaults
  - Managed Identities
  - App Registrations (Entra ID / Azure AD)

### Kubernetes Addons

Your AKS cluster should have:
- **External Secrets Operator** installed ([Installation Guide](https://external-secrets.io/latest/introduction/getting-started/))
- **Stakater Reloader** installed ([Installation Guide](https://github.com/stakater/Reloader)) - Automatically restarts pods when secrets/configmaps change

### Azure Identity Setup

This deployment uses **User-Assigned Managed Identity (UAI)** for secure Key Vault access:
- **UAI** is created and assigned the **Key Vault Secrets Officer** role on the Key Vault
- **UAI is attached to the AKS node pool (VMSS)** so pods can use it
- **External Secrets Operator** uses this identity to sync secrets from Azure Key Vault
- No credentials or secrets needed in configuration files

**Why this approach?**
- ✅ No service principal credentials to manage
- ✅ No passwords or keys stored in Kubernetes
- ✅ Azure RBAC for fine-grained access control
- ✅ Identity lifecycle managed by Azure
- ✅ Follows Azure security best practices

## 📁 Project Structure

```
open-webui-aks-deployment/
├── README.md
├── tf_files/                          # Terraform configurations
│   ├── 0-provider.tf                  # Provider configurations (Azure, Cloudflare, Kubernetes)
│   ├── 1-state.tf                     # Remote state backend configuration
│   ├── 2-locals.tf                    # Local variables and configuration
│   ├── 3-rg.tf                        # Resource group definitions
│   ├── 4-storage.tf                   # Azure Storage Account + Files + Private Endpoint
│   ├── 5-uai.tf                       # User-assigned managed identity
│   ├── 6-kv.tf                        # Azure Key Vault setup with RBAC roles
│   ├── 7-cf_tunnel.tf                 # Cloudflare tunnel configuration
│   ├── 8-app-reg.tf                   # Entra ID (Azure AD) app registration for SSO
│   ├── 9-webui-secret.tf              # WebUI secret key generation
│   ├── 10-uai-nodepool-assignment.tf  # Assign identity to AKS nodes (VMSS)
│   ├── 11-k8s-deployment.tf           # Kubernetes resource deployment
│   └── 12-postgresql.tf               # PostgreSQL Flexible Server + Database + Private Endpoint
│
└── yaml_files/                        # Kubernetes manifests
    ├── 0-namespace.yaml               # Namespace definition
    ├── 1-ollama-pvc.yaml              # Ollama persistent volume claim (Azure Disk)
    ├── 2-1-open-webui-pv.yaml         # Open WebUI persistent volume (Azure Files - static)
    ├── 2-2-open-webui-pvc.yaml        # Open WebUI persistent volume claim (Azure Files)
    ├── 3-secret-store.yaml            # External Secrets store configuration
    ├── 4-external-secret.yaml         # Secret mappings from Key Vault
    ├── 5-config-map.yaml              # Application configuration
    ├── 6-ollama-deployment.yaml       # Ollama deployment
    ├── 7-open-webui-deployment.yaml   # Open WebUI deployment (3 replicas + PostgreSQL)
    ├── 8-ollama-svc.yaml              # Ollama internal service
    ├── 9-open-webui-svc.yaml          # Open WebUI internal service
    ├── 10-cf-tunnel.yaml              # Cloudflare tunnel deployment
    ├── x-netshoot-pod.yaml            # NetShoot debugging pod
    └── x-postgres-client-pod.yaml     # PostgreSQL client debugging pod
```

## 🚀 Quick Start

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/open-webui-aks-deployment.git
cd open-webui-aks-deployment
```

### Step 2: Configure Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Get your AKS credentials
az aks get-credentials --resource-group YOUR_RG --name YOUR_AKS_CLUSTER
```

### Step 3: Update Terraform Variables

Edit `tf_files/2-locals.tf` with your values:

```terraform
locals {
  subscription_id           = "YOUR_AZURE_SUBSCRIPTION_ID"
  location                  = "eastasia"
  
  # Cloudflare
  cf_account_id            = "YOUR_CLOUDFLARE_ACCOUNT_ID"
  cf_zone_id               = "YOUR_CLOUDFLARE_ZONE_ID"
  cf_zone_name             = "yourdomain.com"
  dns_record_name          = "open-webui"
  
  # Tags
  TAG_OWNER                = "your-team@example.com"
  TAG_CREATED_BY           = "your-email@example.com"
}
```

### Step 4: Update Provider Configuration

Edit `tf_files/0-provider.tf`:

```terraform
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "your-aks-context"
}

provider "azuread" {
  tenant_id = "YOUR_AZURE_TENANT_ID"
}
```

### Step 5: Deploy Infrastructure with Terraform

```bash
cd tf_files

# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

### Step 6: Update Kubernetes Manifests

Edit `yaml_files/3-secret-store.yaml` with your **User-Assigned Managed Identity Client ID**:

```yaml
spec:
  provider:
    azurekv:
      authType: ManagedIdentity
      identityId: "YOUR_MANAGED_IDENTITY_CLIENT_ID"  # Get from Terraform output or Azure Portal
      vaultUrl: "https://your-keyvault-name.vault.azure.net/"
```

**Important**: The `identityId` is the **Client ID** (not Object ID) of your User-Assigned Managed Identity. You can find it:
```bash
# From Terraform output
terraform output

# Or from Azure CLI
az identity show --name YOUR_UAI_NAME --resource-group YOUR_RG --query clientId -o tsv
```

Edit `yaml_files/5-config-map.yaml`:

```yaml
data:
  WEBUI_URL: "https://open-webui.yourdomain.com"
  MICROSOFT_CLIENT_ID: "YOUR_MICROSOFT_CLIENT_ID"
  MICROSOFT_CLIENT_TENANT_ID: "YOUR_MICROSOFT_TENANT_ID"
  MICROSOFT_REDIRECT_URI: "https://open-webui.yourdomain.com/oauth/microsoft/callback"
```

### Step 6a: Install Stakater Reloader (Optional but Recommended)

Stakater Reloader automatically restarts pods when their secrets or configmaps are updated:

```bash
# Install using Helm
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
helm install reloader stakater/reloader --namespace kube-system

# Or using kubectl
kubectl apply -f https://raw.githubusercontent.com/stakater/Reloader/master/deployments/kubernetes/reloader.yaml
```

The deployments already have the required annotations:
```yaml
annotations:
  secret.reloader.stakater.com/auto: "true"
  configmap.reloader.stakater.com/auto: "true"
```

### Step 7: Deploy Kubernetes Resources

```bash
cd ../yaml_files

# Apply all manifests in order
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
```

### Step 8: Verify Deployment

```bash
# Check pod status
kubectl get pods -n open-webui

# Check services
kubectl get svc -n open-webui

# View logs
kubectl logs -n open-webui deployment/open-webui
kubectl logs -n open-webui deployment/ollama
```

## ⚙️ Configuration

### Database and Storage Architecture

This deployment uses a **hybrid storage strategy** optimized for production workloads:

#### PostgreSQL Database (Replaces SQLite)

**Why PostgreSQL instead of SQLite?**

```
SQLite Limitations:
❌ Single-writer lock (no horizontal scaling)
❌ File-based (network storage issues)
❌ Limited concurrent connections
❌ Not designed for multi-replica deployments

PostgreSQL Benefits:
✅ True multi-user concurrent access
✅ Horizontal scaling with replicas (3 Open WebUI pods)
✅ ACID compliance with better isolation
✅ Advanced features (full-text search, JSON, vectors)
✅ Automatic backups and point-in-time recovery
✅ Private endpoint security
```

**Database Configuration:**

```yaml
# Terraform provisions:
- PostgreSQL Flexible Server (version 18)
- SKU: B_Standard_B1ms (Burstable tier, cost-optimized)
- Storage: 32GB with P4 performance tier
- Network: Private endpoint + delegated subnet
- Backup: 7-day retention
- Maintenance: Tuesday 1 AM UTC

# Open WebUI connects via DATABASE_URL environment variable:
DATABASE_URL: postgresql://admin:password@psql-server.postgres.database.azure.com:5432/openwebuidb?sslmode=require
```

**Database Usage:**
- **Application data**: User accounts, settings, conversations, history
- **Vector embeddings**: Semantic search and RAG functionality (using pgvector extension)
- **All transactional data**: Replaces SQLite completely

#### Azure Files Storage (Shared File Storage)

**Storage Purpose:**

```
Azure Files is used ONLY for:
├─ User file uploads (documents, images)
├─ Temporary cache files
├─ Session data
└─ Static assets

NOT used for:
❌ Database files (PostgreSQL handles this)
❌ Vector storage (PostgreSQL with pgvector)
```

**Storage Configuration:**

```yaml
# Terraform provisions:
- Storage Account with Standard tier
- Azure Files share (50GB, SMB protocol)
- Private endpoint for secure access
- Private DNS zone integration
- Static provisioning with PV/PVC

# Mount configuration:
- Access Mode: ReadWriteMany (RWX)
- Protocol: SMB
- Mount Options: dir_mode=0777, file_mode=0777
- Mount Path: /app/backend/data
```

**Why Azure Files with Private Endpoint?**

```
Security Benefits:
✅ No public internet access to storage
✅ Traffic stays within Azure backbone
✅ Private DNS resolution
✅ NSG and firewall controls

Performance Benefits:
✅ Lower latency (<5ms within region)
✅ Higher throughput
✅ Better reliability

Compliance Benefits:
✅ Data never traverses public internet
✅ Meets regulatory requirements
✅ Audit trail via Azure Monitor
```

#### Ollama Model Storage (Azure Managed Disk)

**Storage Configuration:**

```yaml
# Dynamic provisioning with managed-csi:
- Storage Class: managed-csi (Standard SSD)
- Access Mode: ReadWriteOnce (RWO)
- Size: 50GB
- Performance: 500 IOPS, 60 MB/s

# Why Azure Disk for models:
✅ High IOPS for model loading
✅ Low latency block storage
✅ Cost-effective for large files
✅ Automatic zone placement with WaitForFirstConsumer
```

#### Storage Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Open WebUI Pods (3 replicas)                                │
│  ├─ App Logic (Python/FastAPI)                               │
│  ├─ DATABASE_URL → PostgreSQL Flexible Server                │
│  ├─ /app/backend/data → Azure Files PV (RWX)                 │
│  └─ Vectors & Embeddings → PostgreSQL (pgvector)             │
└────────┬────────────────────────────────────┬────────────────┘
         │                                    │
         ↓                                    ↓
┌────────────────────────────┐    ┌─────────────────────────┐
│  Azure Files (SMB)         │    │  PostgreSQL Flexible     │
│  ├─ Private Endpoint       │    │  ├─ Private Endpoint     │
│  ├─ 50GB Standard          │    │  ├─ 32GB Storage         │
│  ├─ RWX (multi-pod)        │    │  ├─ B1ms (2vCore/2GB)   │
│  └─ File uploads/cache     │    │  └─ ACID + pgvector      │
└────────────────────────────┘    └─────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│  Ollama Pod (1 replica)                                     │
│  ├─ Model inference                                         │
│  └─ /root/.ollama → Azure Disk PVC (RWO)                    │
└─────────────────────────────┬──────────────────────────────┘
                              │
                              ↓
                    ┌───────────────────────┐
                    │  Azure Managed Disk   │
                    │  ├─ Standard SSD      │
                    │  ├─ 50GB              │
                    │  ├─ RWO (single-pod)  │
                    │  └─ LLM models        │
                    └───────────────────────┘
```

#### Connection String Configuration

The PostgreSQL connection string is stored in Azure Key Vault and synced via External Secrets Operator:

```yaml
# In Key Vault (managed by Terraform):
postgres-connection-string: 
  "postgresql://admin:password@psql-server.postgres.database.azure.com:5432/dbname?sslmode=require"

# Synced to Kubernetes Secret (open-webui-secrets):
DATABASE_URL: <value-from-key-vault>

# Referenced in Open WebUI Deployment:
env:
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: open-webui-secrets
      key: DATABASE_URL
```

### Entra ID (Azure AD) App Registration for SSO Authentication

This deployment uses **Microsoft Entra ID (formerly Azure AD) as the Identity Provider (IdP)** for Single Sign-On authentication via OAuth 2.0/OIDC protocol.

1. **Create App Registration** in Azure Portal:
   - Navigate to **Microsoft Entra ID** → **App registrations** → **New registration**
   - Name: `open-webui-app`
   - Supported account types: `Accounts in this organizational directory only (Single tenant)`
   - Redirect URI: `Web` → `https://open-webui.yourdomain.com/oauth/microsoft/callback`

2. **Configure Authentication**:
   - Go to **Authentication** → **Implicit grant and hybrid flows**
   - ✅ **Check "ID tokens"** (used for hybrid flows)
   - ⚠️ Leave "Access tokens" unchecked (not needed for this flow)
   - Save changes

3. **Configure API Permissions**:
   - Go to **API permissions** → **Add a permission**
   - Select **Microsoft Graph** → **Delegated permissions**
   - Add the following permissions:
     - `User.Read` - Read user profile
     - `openid` - OpenID Connect sign-in
     - `email` - Read user's email
     - `profile` - Read user's basic profile
     - `offline_access` - Maintain access to data
   - Click **Grant admin consent** for your organization

4. **Create Client Secret**:
   - Go to **Certificates & secrets** → **Client secrets** → **New client secret**
   - Description: `open-webui-secret`
   - Expiration: Choose appropriate duration (recommended: 24 months)
   - Copy the secret **Value** (only shown once)
   - Store the secret in Azure Key Vault using Terraform or manually

5. **Note the following values** (needed for configuration):
   - **Application (client) ID** - Found on the Overview page
   - **Directory (tenant) ID** - Found on the Overview page
   - **Client secret value** - Copied in previous step

**Security Notes:**
- This configuration uses OAuth 2.0 Authorization Code flow with OIDC
- ID tokens are JWT tokens that contain user identity claims
- Tokens are validated using Microsoft's public keys
- Refresh tokens allow seamless re-authentication without re-login

### User-Assigned Managed Identity for Key Vault Access

The Terraform configuration automatically:
1. **Creates a User-Assigned Managed Identity (UAI)**
2. **Assigns the "Key Vault Secrets Officer" role** to the UAI on the Key Vault
3. **Attaches the UAI to the AKS node pool (VMSS)** using Azure CLI

This allows pods running on the AKS cluster to:
- Access secrets from Azure Key Vault without credentials
- Use External Secrets Operator with Managed Identity authentication
- Follow Azure security best practices (no passwords/keys in code)

**Terraform files involved:**
- `5-uai.tf` - Creates the User-Assigned Managed Identity
- `6-kv.tf` - Creates Key Vault and assigns RBAC roles
- `10-uai-nodepool-assignment.tf` - Attaches UAI to AKS VMSS

### Cloudflare Tunnel Setup

The Terraform configuration automatically creates:
- Cloudflare Zero Trust Tunnel
- DNS CNAME record pointing to the tunnel
- Tunnel token stored in Azure Key Vault

### Storage Configuration

By default, the deployment uses:
- **Ollama PVC**: 50GB Azure Managed Disk (SSD)
- **Open WebUI PVC**: Azure Managed Disk (configurable size)

To modify storage sizes, edit the PVC manifests:

```yaml
# yaml_files/1-ollama-pvc.yaml
spec:
  resources:
    requests:
      storage: 100Gi  # Change size here
```

## 📚 Usage Examples

### Example 1: Accessing Open WebUI

Once deployed, access Open WebUI at:
```
https://open-webui.yourdomain.com
```

Log in using your Microsoft account (Azure AD).

### Example 2: Loading Ollama Models

```bash
# Connect to the Ollama pod
kubectl exec -it -n open-webui deployment/ollama -- bash

# Pull a model (e.g., llama2)
ollama pull llama2

# List available models
ollama list
```

### Example 3: Verifying PostgreSQL Database Connection

```bash
# Deploy PostgreSQL client pod for debugging
kubectl apply -f yaml_files/x-postgres-client-pod.yaml

# Wait for pod to be ready
kubectl wait --for=condition=ready pod psql-client -n open-webui --timeout=120s

# Connect to PostgreSQL database
kubectl exec -it psql-client -n open-webui -- bash

# Inside the pod, connect to database
psql "host=psql-openwebui.postgres.database.azure.com port=5432 dbname=openwebuidb user=openwebuiadmin sslmode=require"
# Enter password when prompted (stored in Key Vault)

# Check database tables
\dt

# Check database size
SELECT pg_database_size('openwebuidb');

# Check active connections
SELECT * FROM pg_stat_activity;

# Exit
\q
exit

# Clean up debug pod
kubectl delete pod psql-client -n open-webui
```

### Example 4: Network Debugging with NetShoot

```bash
# Deploy NetShoot pod for network troubleshooting
kubectl apply -f yaml_files/x-netshoot-pod.yaml

# Wait for pod to be ready
kubectl wait --for=condition=ready pod netshoot -n open-webui --timeout=60s

# Exec into NetShoot pod
kubectl exec -it netshoot -n open-webui -- bash

# Test DNS resolution
nslookup open-webui.open-webui.svc.cluster.local
nslookup ollama.open-webui.svc.cluster.local
nslookup psql-openwebui.postgres.database.azure.com

# Test connectivity to services
curl http://open-webui:80
curl http://ollama:11434

# Test PostgreSQL connectivity
nc -zv psql-openwebui.postgres.database.azure.com 5432

# Test Azure Files storage connectivity
nslookup stopenwebui.file.core.windows.net

# Check routing
traceroute open-webui.yourdomain.com

# Exit
exit

# Clean up debug pod
kubectl delete pod netshoot -n open-webui
```

### Example 5: Checking External Secrets Sync

```bash
# Verify External Secret status
kubectl get externalsecrets -n open-webui

# Check synced Kubernetes secret
kubectl get secret open-webui-secrets -n open-webui -o yaml

# Force immediate sync (don't wait for 1-hour refresh)
kubectl annotate externalsecret open-webui-secrets \
  -n open-webui force-sync=$(date +%s) --overwrite
```

### Example 6: Checking Azure Files Storage

```bash
# Check PV status
kubectl get pv | grep open-webui

# Check PVC binding
kubectl get pvc -n open-webui

# Check mounted storage from Open WebUI pod
kubectl exec -n open-webui deployment/open-webui -- df -h /app/backend/data

# List files in Azure Files mount
kubectl exec -n open-webui deployment/open-webui -- ls -lah /app/backend/data

# Check storage account private endpoint resolution
kubectl exec -n open-webui deployment/open-webui -- nslookup stopenwebui.file.core.windows.net
```

### Example 7: Scaling Open WebUI with PostgreSQL

```bash
# Now you can safely scale to multiple replicas (PostgreSQL supports concurrency!)
kubectl scale deployment open-webui -n open-webui --replicas=5

# Check replica distribution
kubectl get pods -n open-webui -l app=open-webui -o wide

# Monitor logs from all replicas
kubectl logs -n open-webui -l app=open-webui --tail=50 -f
```

### Example 8: Monitoring Database Performance

```bash
# Connect to PostgreSQL
kubectl exec -it psql-client -n open-webui -- bash
psql "host=psql-openwebui.postgres.database.azure.com port=5432 dbname=openwebuidb user=openwebuiadmin sslmode=require"

# Check slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

# Check database connections
SELECT count(*) FROM pg_stat_activity;

# Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

# Exit
\q
exit
```

### Example 9: Viewing Application Logs

```bash
# Stream Open WebUI logs from all replicas
kubectl logs -f -n open-webui -l app=open-webui --tail=100

# Stream logs from specific pod
kubectl logs -f -n open-webui deployment/open-webui --tail=50

# Stream Ollama logs
kubectl logs -f -n open-webui deployment/ollama

# Stream Cloudflare tunnel logs
kubectl logs -f -n open-webui deployment/cloudflared

# View logs with timestamps
kubectl logs -n open-webui deployment/open-webui --timestamps=true
```

### Example 10: Updating Configuration

```bash
# Edit ConfigMap
kubectl edit configmap open-webui-config -n open-webui

# Restart deployment to apply changes (Stakater Reloader does this automatically!)
kubectl rollout restart deployment open-webui -n open-webui

# Watch rollout status
kubectl rollout status deployment open-webui -n open-webui
```

## 🔧 Customization

### Change Resource Limits

Edit the deployment files to adjust CPU and memory:

```yaml
# yaml_files/7-open-webui-deployment.yaml
resources:
  requests:
    memory: "2Gi"
    cpu: "200m"
  limits:
    memory: "4Gi"
    cpu: "1000m"
```

### Add Custom Environment Variables

Add to `yaml_files/5-config-map.yaml`:

```yaml
data:
  # Your custom variables
  CUSTOM_VAR: "value"
  ANOTHER_VAR: "another-value"
```

### Enable Image Generation

Update ConfigMap:

```yaml
data:
  ENABLE_IMAGE_GENERATION: "true"
```

### Change Ollama Base URL

If using external Ollama:

```yaml
data:
  OLLAMA_BASE_URL: "https://external-ollama.example.com"
```

### Add Node Selectors or Tolerations

Edit deployment files to schedule pods on specific nodes:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        workload: ai
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "ai-workload"
        effect: "NoSchedule"
```

### Configure Session Affinity for Multiple Replicas

The Open WebUI service is configured with **ClientIP session affinity** to ensure user sessions are maintained across the 3 replicas:

```yaml
# yaml_files/9-open-webui-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: open-webui-svc
  namespace: open-webui
spec:
  type: ClusterIP
  selector:
    app: open-webui
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 hours
```

**Why Session Affinity is Important:**

- **Session Persistence**: Each client IP is consistently routed to the same pod for 3 hours
- **WebSocket Connections**: Maintains long-lived connections for real-time chat features
- **User Experience**: Prevents session disruptions when load balancing across replicas
- **Stateful Interactions**: While PostgreSQL handles shared data persistence, in-memory session state is maintained per pod

**Timeout Configuration:**

- **10800 seconds (3 hours)**: Balances session persistence with load distribution
- After timeout, client may be routed to a different pod (session data persists in PostgreSQL)
- Adjust timeout based on your usage patterns:
  ```yaml
  # Shorter timeout for better load distribution
  timeoutSeconds: 3600  # 1 hour
  
  # Longer timeout for extended sessions
  timeoutSeconds: 28800  # 8 hours
  ```

**Important Notes:**

- Session affinity is based on client IP, not authentication
- If client IP changes (e.g., mobile network switching), user may hit a different pod
- PostgreSQL ensures data consistency across all replicas
- Without session affinity, users might experience unexpected behavior with 3+ replicas

### Use Different Storage Class

Modify PVC to use different storage:

```yaml
spec:
  storageClassName: managed-premium  # Or your custom storage class
```

### Enable/Disable Automatic Reloading

The deployments use Stakater Reloader annotations to automatically restart when secrets/configmaps change:

```yaml
# Enable auto-reload for both secrets and configmaps (default)
metadata:
  annotations:
    secret.reloader.stakater.com/auto: "true"
    configmap.reloader.stakater.com/auto: "true"

# Or watch specific secrets/configmaps
metadata:
  annotations:
    secret.reloader.stakater.com/reload: "open-webui-secrets"
    configmap.reloader.stakater.com/reload: "open-webui-config"

# Disable auto-reload
# Simply remove the annotations or set to "false"
```

### Multi-Region Deployment

To deploy in multiple regions:

1. Create separate `locals-{region}.tf` files
2. Use Terraform workspaces:
   ```bash
   terraform workspace new eastasia
   terraform workspace new westeurope
   ```

## 🐛 Troubleshooting

### PostgreSQL Connection Issues

```bash
# Check if PostgreSQL server is accessible
kubectl exec -it psql-client -n open-webui -- bash
nc -zv psql-openwebui.postgres.database.azure.com 5432

# Test DNS resolution
nslookup psql-openwebui.postgres.database.azure.com

# Verify DATABASE_URL secret is synced
kubectl get secret open-webui-secrets -n open-webui -o jsonpath='{.data.DATABASE_URL}' | base64 -d

# Check PostgreSQL server status in Azure
az postgres flexible-server show --resource-group YOUR_RG --name psql-openwebui

# Check if private endpoint is working
az network private-endpoint show --resource-group YOUR_RG --name pe-psql-openwebui

# View Open WebUI logs for database errors
kubectl logs -n open-webui deployment/open-webui | grep -i "database\|postgres\|connection"

# Common PostgreSQL errors:
# - "could not connect to server": Check private endpoint and NSG rules
# - "password authentication failed": Verify credentials in Key Vault
# - "SSL required": Ensure connection string has sslmode=require
```

### Azure Files Mount Issues

```bash
# Check if PV is bound to PVC
kubectl get pv | grep open-webui
kubectl get pvc -n open-webui

# Verify storage account key secret exists
kubectl get secret open-webui-secrets -n open-webui -o jsonpath='{.data.azurestorageaccountkey}' | base64 -d

# Test storage account accessibility
kubectl exec -it netshoot -n open-webui -- bash
nslookup stopenwebui.file.core.windows.net

# Check private endpoint resolution
# Should resolve to private IP (10.x.x.x), not public IP
dig stopenwebui.file.core.windows.net

# Check mount inside Open WebUI pod
kubectl exec -n open-webui deployment/open-webui -- df -h | grep /app/backend/data
kubectl exec -n open-webui deployment/open-webui -- ls -lah /app/backend/data

# Common Azure Files errors:
# - "mount error(13): Permission denied": Check storage account key in secret
# - "mount error(115): Operation now in progress": Network connectivity issue, check private endpoint
# - "SMB connection failed": Verify SMB protocol is enabled on storage account
```

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod -n open-webui POD_NAME

# Check Open WebUI specific events
kubectl get events -n open-webui --field-selector involvedObject.name=open-webui --sort-by='.lastTimestamp'

# Common issues:
# - PVC not bound: Check storage class and availability
# - Image pull errors: Verify image name and registry access
# - Resource limits: Check node capacity
# - Database connection timeout: Check PostgreSQL private endpoint
# - Azure Files mount failed: Check storage account key secret
```

### Database Performance Issues

```bash
# Connect to PostgreSQL and check performance
kubectl exec -it psql-client -n open-webui -- bash
psql "host=psql-openwebui.postgres.database.azure.com port=5432 dbname=openwebuidb user=openwebuiadmin sslmode=require"

# Check active connections
SELECT count(*) FROM pg_stat_activity WHERE datname = 'openwebuidb';

# Check for long-running queries
SELECT pid, usename, state, query, now() - query_start AS duration
FROM pg_stat_activity
WHERE state != 'idle'
  AND query_start < now() - interval '30 seconds'
ORDER BY duration DESC;

# Check database locks
SELECT * FROM pg_locks WHERE NOT granted;

# Check table bloat
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

# Exit
\q
exit
```

### Multiple Replicas Not Working Together

```bash
# Check if all replicas are connecting to same PostgreSQL database
kubectl logs -n open-webui -l app=open-webui --tail=20 | grep -i "database\|connected"

# Verify all pods can reach database
for pod in $(kubectl get pods -n open-webui -l app=open-webui -o name); do
  echo "Testing $pod:"
  kubectl exec -n open-webui $pod -- timeout 5 bash -c "echo > /dev/tcp/psql-openwebui.postgres.database.azure.com/5432" && echo "OK" || echo "FAILED"
done

# Check session affinity (should NOT be needed with PostgreSQL)
kubectl get svc open-webui -n open-webui -o jsonpath='{.spec.sessionAffinity}'

# Monitor concurrent database connections
kubectl exec -it psql-client -n open-webui -- bash
watch -n 2 "psql 'host=psql-openwebui.postgres.database.azure.com port=5432 dbname=openwebuidb user=openwebuiadmin sslmode=require' -c 'SELECT count(*) FROM pg_stat_activity WHERE datname = '\''openwebuidb'\'';'"
```

### Secret Sync Issues

```bash
# Verify External Secrets Operator is running
kubectl get pods -n external-secrets

# Check SecretStore configuration
kubectl get secretstore -n open-webui

# Check ExternalSecret status
kubectl get externalsecret -n open-webui
kubectl describe externalsecret open-webui-secrets -n open-webui

# Verify UAI is attached to VMSS
az vmss identity show --resource-group YOUR_NODE_RG --name YOUR_VMSS_NAME

# Verify UAI has Key Vault access
az role assignment list --assignee YOUR_UAI_CLIENT_ID --scope /subscriptions/YOUR_SUB_ID/resourceGroups/YOUR_RG/providers/Microsoft.KeyVault/vaults/YOUR_KV_NAME

# Check if Reloader is installed and running
kubectl get pods -n kube-system -l app=reloader

# Test Key Vault access from a pod
kubectl run -it --rm debug --image=mcr.microsoft.com/azure-cli --restart=Never -n open-webui -- bash
# Inside the pod:
az login --identity
az keyvault secret list --vault-name YOUR_KV_NAME
```

### Pods Not Restarting After Secret Update

```bash
# Verify Stakater Reloader is installed
kubectl get deployment -n kube-system reloader

# Check Reloader logs
kubectl logs -n kube-system deployment/reloader

# Verify deployment has correct annotations
kubectl get deployment open-webui -n open-webui -o yaml | grep reloader

# Manually trigger reload by updating annotation
kubectl patch deployment open-webui -n open-webui \
  -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"reloader.stakater.com/reload\":\"$(date +%s)\"}}}}}"
```

### Cloudflare Tunnel Not Working

```bash
# Check tunnel pod logs
kubectl logs -n open-webui deployment/cloudflared

# Verify tunnel token in Key Vault
az keyvault secret show --vault-name YOUR_KV --name cf-tunnel-token

# Check DNS propagation
nslookup open-webui.yourdomain.com
```

### Authentication Issues

```bash
# Verify App Registration redirect URI matches
# Check client ID and tenant ID in ConfigMap
kubectl get configmap open-webui-config -n open-webui -o yaml

# Verify client secret is synced
kubectl get secret open-webui-secrets -n open-webui
```

## 🔒 Security Considerations

### ✅ Best Practices Implemented

- **Secrets Management**: All secrets stored in Azure Key Vault, not in code
- **Managed Identities**: User-Assigned Managed Identity with Key Vault Secrets Officer role (no credentials in files)
- **RBAC Authorization**: Azure RBAC for Key Vault access control
- **VMSS Identity Binding**: UAI attached to AKS node pool for pod-level access
- **Network Security**: Cloudflare Tunnel eliminates public IP exposure
- **RBAC**: Kubernetes RBAC controls access to resources
- **OAuth 2.0**: Secure authentication via Azure AD

### ⚠️ Additional Security Measures

1. **Enable RBAC** on your AKS cluster
2. **Use Network Policies** to restrict pod-to-pod communication
3. **Enable Pod Security Standards**
4. **Rotate secrets regularly** in Azure Key Vault
5. **Monitor access logs** via Azure Monitor
6. **Use Azure Policy** for compliance enforcement

### 🔐 Secrets to Store in Key Vault

Required secrets:
- `WEBUI_SECRET_KEY`: Django secret key for Open WebUI
- `MICROSOFT_CLIENT_SECRET`: Azure AD app client secret
- `TUNNEL_TOKEN`: Cloudflare tunnel token

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Open WebUI](https://github.com/open-webui/open-webui) - The amazing WebUI for LLMs
- [Ollama](https://ollama.ai/) - Run large language models locally
- [External Secrets Operator](https://external-secrets.io/) - Kubernetes secret management
- [Stakater Reloader](https://github.com/stakater/Reloader) - Automatic pod reloading on config changes
- [Cloudflare Zero Trust](https://www.cloudflare.com/zero-trust/) - Secure network access

## 📞 Support

For issues and questions:
- Open an [Issue](https://github.com/yourusername/open-webui-aks-deployment/issues)
- Check existing [Discussions](https://github.com/yourusername/open-webui-aks-deployment/discussions)

---

**⭐ If you find this project helpful, please consider giving it a star!**
