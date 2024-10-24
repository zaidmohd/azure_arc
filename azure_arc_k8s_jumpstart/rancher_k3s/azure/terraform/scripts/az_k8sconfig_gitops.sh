#!/bin/sh
# <--- Change the following environment variables according to your Azure service principal name --->
echo "Exporting environment variables"
export appId='<Your Azure service principal name>'
export password='<Your Azure service principal password>'
export tenantId='<Your Azure tenant ID>'
export resourceGroup='tailwind-manufacturing-chicago-rg'
export arcClusterName='twt-k3s'
export appClonedRepo='https://github.com/zaidmohd/azure-arc-jumpstart-apps'
export namespace='hello-arc'

# # Installing Helm 3
# echo "Installing Helm 3"
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh

# # Installing Azure CLI & Azure Arc Extensions
# echo "Installing Azure CLI & Azure Arc Extensions"
# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# # Login to Azure
# echo "Log in to Azure with Service Principal"
# az login --service-principal --username $appId --password=$password --tenant $tenantId

# Create a namespace for your app & ingress resources
kubectl create ns $namespace

# Add the official stable repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Use Helm to deploy an NGINX ingress controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace $namespace

# Create GitOps config for Hello-Arc app
echo "Creating GitOps config for Hello-Arc app"
az k8s-configuration flux create \
--resource-group $resourceGroup \
--cluster-name $arcClusterName \
--cluster-type connectedClusters \
--name config-helloarc \
--scope namespace \
--namespace $namespace \
--kind git \
--url $appClonedRepo \
--branch main --sync-interval 3s \
--kustomization name=app path=./hello-arc/yaml

# Create GitOps config for Hello-Arc Ingress
echo "Creating GitOps config for Hello-Arc Ingress"
az k8s-configuration flux create \
--resource-group $resourceGroup \
--cluster-name $arcClusterName \
--cluster-type connectedClusters \
--name config-helloarc-ingress \
--scope namespace \
--namespace $namespace \
--kind git \
--url $appClonedRepo \
--branch main \
--kustomization name=app path=./hello-arc/ingress

az k8s-configuration flux create --resource-group "tailwindtraders-hci-rg" --cluster-name "twt-hci-aks" --cluster-type connectedClusters --name config-hello-arc --scope namespace --namespace twt-app --kind git --url "https://github.com/zaidmohd/azure-arc-jumpstart-apps" --branch main --sync-interval 3s --kustomization name=app path=./hello-arc/yaml

 az k8s-configuration flux delete --resource-group "tailwindtraders-hci-rg" --cluster-name "twt-hci-aks" --cluster-type connectedClusters --name config-app
