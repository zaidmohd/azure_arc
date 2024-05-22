export ARC_CLUSTER_NAME="Arc-K3s-Demo-lVOa"

export RESOURCE_GROUP="zm-k3srg05"
export LOCATION="eastus"
export AZURE_STORAGE_ACCOUNT="oidcissuer$(openssl rand -hex 4)"
export AZURE_STORAGE_CONTAINER="oidc-test"
export SUBSCRIPTION="$(az account show --query id --output tsv)"
export AZURE_TENANT_ID="$(az account show -s $SUBSCRIPTION --query tenantId -otsv)"
export KEYVAULT_NAME="azwi4-kv-$(openssl rand -hex 4)"
export KEYVAULT_SECRET_NAME="my-secret"
export USER_ASSIGNED_IDENTITY_NAME="myIdentity"
export SERVICE_ACCOUNT_ISSUER="https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/oidc-test"
export FEDERATED_IDENTITY_CREDENTIAL_NAME="myFedIdentity"
export SERVICE_ACCOUNT_NAMESPACE="default"
export SERVICE_ACCOUNT_NAME="workload-identity-sa"

az login --identity
az account set --subscription "${SUBSCRIPTION}"


