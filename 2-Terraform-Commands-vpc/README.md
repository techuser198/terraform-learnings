# Terraform Commands Guide

## Overview
Terraform uses a set of core commands to manage infrastructure as code. This guide explains the essential commands you'll use daily.

## Core Commands

### 1. **terraform init**
Initializes a Terraform working directory. This must be run first.
- Downloads required provider plugins
- Sets up the backend for state management
- Creates `.terraform` directory
```bash
terraform init
```

### 2. **terraform validate**
Checks the syntax and configuration of your Terraform files for errors.
- Validates HCL syntax
- Checks resource references
- Does NOT require cloud credentials
```bash
terraform validate
```

### 3. **terraform plan**
Shows what Terraform will do before making changes (dry-run).
- Creates an execution plan
- Shows resources to be created, modified, or destroyed
- Helps review changes before applying
```bash
terraform plan
terraform plan -out=planfile  # Save plan to file
```

### 4. **terraform apply**
Executes the planned changes and creates/modifies actual infrastructure.
- Asks for confirmation before proceeding
- Updates the state file
- Creates real resources in your cloud provider
```bash
terraform apply
terraform apply planfile  # Apply saved plan
```

### 5. **terraform destroy**
Removes all resources defined in your Terraform configuration.
- Deletes infrastructure from the cloud provider
- Asks for confirmation before proceeding
- Useful for cleaning up test environments
```bash
terraform destroy
```

## Workflow Example
```
init → validate → plan → apply → (manage) → destroy
```
