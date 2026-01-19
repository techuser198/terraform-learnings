
# Terraform and Google Cloud Setup on WSL

## Prerequisites
- Windows Subsystem for Linux (WSL 2) installed
- Ubuntu distribution on WSL

## Installing Terraform

1. **Update package manager**
    ```bash
    sudo apt-get update
    ```

2. **Install required dependencies**
    ```bash
    sudo apt-get install -y gnupg software-properties-common
    ```

3. **Add HashiCorp GPG key**
    ```bash
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    ```

4. **Add HashiCorp repository**
    ```bash
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    ```

5. **Install Terraform**
    ```bash
    sudo apt-get update && sudo apt-get install terraform
    ```

6. **Verify installation**
    ```bash
    terraform version
    ```

## Installing Google Cloud SDK (gcloud)

1. **Add Google Cloud SDK repository**
    ```bash
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    ```

2. **Import Google Cloud public key**
    ```bash
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    ```

3. **Install gcloud SDK**
    ```bash
    sudo apt-get update && sudo apt-get install google-cloud-sdk
    ```

4. **Initialize gcloud**
    ```bash
    gcloud init
    ```

5. **Verify installation**
    ```bash
    gcloud version

    The instructions look mostly solid, but I'd add a verification step at the end to ensure both tools work together:

    ```bash
    # Verify both Terraform and gcloud can communicate
    terraform version
    gcloud auth list
    gcloud config list
    ```

    Also, consider adding a note that users should authenticate with Google Cloud before using Terraform:

    ```bash
    gcloud auth application-default login
    ```

    This ensures Terraform can access GCP resources. The original steps should work, but these additions provide a complete validation.

