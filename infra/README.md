# Azure deployment

This Terraform configuration creates the cloud pieces required by the assignment.

- Azure Blob static website for the frontend
- Azure Container App for the Python API
- Azure Managed Redis used by the API
- Azure Container Registry for the private API image
- Log Analytics and a Container Apps environment

Terraform creates Managed Redis and injects a TLS connection string into the Container App secret named `redis-url`. Registry credentials stay in a local `terraform.tfvars` file and out of the repository.

## Deploy

1. Install Azure CLI and Terraform.
2. Run `az login` and set the subscription used in `terraform.tfvars`.
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in the values locally. Keep that file untracked.
4. For a private Azure Container Registry image, create the registry and build the API image before the final apply.

   ```bash
   az group create --name rg-taskboard --location spaincentral
   az acr create --resource-group rg-taskboard --name <unique-acr-name> --sku Basic --admin-enabled true --location spaincentral
   az acr build --registry <unique-acr-name> --image taskboard-api:linux-amd64 ../api
   az acr credential show --name <unique-acr-name>
   ```

   Put the registry login server, username, and password in the local `terraform.tfvars` file. Set `api_image` to `<unique-acr-name>.azurecr.io/taskboard-api:linux-amd64`.
5. Run `terraform init`, `terraform plan`, and `terraform apply`.
6. The `config.js` blob is generated with the Container App URL, and `ALLOWED_ORIGINS` is passed to the API.
7. Record the public URLs and Azure resource inventory before deleting the resource group.

For a real submission, capture the Container App, Storage Account static website, Managed Redis, Container Registry, and Log Analytics resources in the Azure portal. Never commit `terraform.tfvars`, passwords, or connection strings.
