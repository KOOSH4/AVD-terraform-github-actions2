# Azure Virtual Desktop (AVD) Infrastructure as Code with GitHub Actions

This repository contains Terraform configurations for deploying and managing Azure Virtual Desktop infrastructure using only Microsoft Entra ID (formerly Azure AD) for cloud-native identity management, without any dependency on Active Directory Domain Services or Kerberos. The infrastructure is deployed and managed through GitHub Actions for automated deployments.

## 🚀 Features

- Automated AVD infrastructure deployment using Terraform and GitHub Actions
- Complete AVD environment setup including:
  - Host Pools
  - Application Groups (Desktop and RemoteApp)
  - Workspaces
  - Session Hosts
  - Networking components
  - FSLogix Profile Storage
  - Monitoring and Diagnostics
- Azure AD integration
- FSLogix configuration
- Monitoring with Log Analytics and Azure Monitor

## 📋 Prerequisites

- Azure Subscription
- GitHub Account
- Azure AD permissions to create and manage resources
- Terraform v1.0.0 or later
- Azure CLI

## 🛠️ Infrastructure Components

The deployment creates the following resource groups and components:

- **AVD Service Components** (`rg-AVD-Service-wstrp`)
  - Host Pool
  - Workspace
  - Application Groups

- **Session Hosts** (`rg-AVD-SessionHosts-wstrp`)
  - Virtual Machines
  - Network Interfaces

- **Network Resources** (`rg-AVD-Network-wstrp`)
  - Virtual Network
  - Subnets

- **Storage** (`rg-AVD-Storage-wstrp`)
  - FSLogix Profile Storage
  - File Shares

- **Monitoring** (`rg-AVD-Monitoring-wstrp`)
  - Log Analytics Workspace
  - Diagnostic Settings
  - Metric Alerts

## 🔧 Configuration

1. Clone this repository
2. Update the `terraform.tfvars` file with your specific values
3. Configure GitHub Actions secrets:
   - AZURE_CLIENT_ID
   - AZURE_SUBSCRIPTION_ID
   - AZURE_TENANT_ID

4. Configure required RBAC permissions:
   - For storage accounts resource group:
     - File Data SMB Share Elevated Contributor (admin users)
     - Storage File Data SMB Share Contributor (regular users)
   - For session host resource group:
     - Virtual Machine Administrator Login (admin users) 
     - Virtual Machine User Login (regular users)

5. Configure Host Pool settings(RDP Properties):
   - Enable Microsoft Entra single sign-on for authentication
   - Enable CredSSP for RDP security support

6. Add users to appropriate Application Groups:
   - Assign users to Desktop Application Group for full desktop access
   - Assign users to RemoteApp Application Group for specific app access

## 📦 Deployment

The infrastructure can be deployed in two ways:

### Manual Deployment

```bash
terraform init
terraform plan
terraform apply
```

### Automated Deployment (GitHub Actions)

The workflow will automatically trigger on:
- Push to main branch
- Pull request to main branch
- Manual workflow dispatch

## 🔐 Security

- Uses Azure AD authentication
- Implements least-privilege access
- Secure storage of credentials using GitHub Secrets

## 📜 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 🔄 Changelog



## ✨ Authors

- **Olad, Koosha**

