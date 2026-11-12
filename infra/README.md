# Azure deployment

This Terraform configuration creates the three cloud pieces required by the assignment.

- Azure Blob static website for the frontend
- Azure Container App for the Python API
- Azure Cache for Redis used by the API

Terraform creates Redis and injects a TLS connection string into the Container App secret named `redis-url`. The key stays out of the repository and out of the container image.

## Deploy

1. Install Azure CLI and Terraform.
2. Run `az login` and set the subscription used in `terraform.tfvars`.
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in the values locally. Keep that file untracked.
4. Run `terraform init`, `terraform plan`, and `terraform apply`.
5. The `config.js` blob is generated with the Container App URL, and `ALLOWED_ORIGINS` is passed to the API.
6. Delete the resource group after recording the screenshots and video.

For a real submission, capture the Container App, Storage Account static website, and Redis resources in the Azure portal. Never commit `terraform.tfvars`, passwords, or connection strings.
