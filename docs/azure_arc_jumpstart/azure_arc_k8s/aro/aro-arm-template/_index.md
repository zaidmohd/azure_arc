---
type: docs
title: "ARO cluster ARM template"
linkTitle: "ARO cluster ARM template"
weight: 1
description: >
---

## Deploy an Azure Red Hat OpenShift cluster and connect it to Azure Arc using an Azure ARM template

The following README will guide you on how to use the provided [Azure ARM Template](https://docs.microsoft.com/azure/azure-resource-manager/templates/overview) to deploy an [Azure Red Hat OpenShift](https://docs.microsoft.com/azure/openshift/intro-openshift) cluster and connected it as an Azure Arc cluster resource.

## Prerequisites

- Clone the Azure Arc Jumpstart repository

    ```shell
    git clone https://github.com/microsoft/azure_arc.git
    ```

- [Install or update Azure CLI to version 2.6.0 and above](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest). Use the below command to check your current installed version.

  ```shell
  az --version
  ```

- Create Azure service principal (SP)

    To be able to complete the scenario and its related automation, Azure service principal assigned with the “Contributor” role is required. To create it, login to your Azure account run the below command (this can also be done in [Azure Cloud Shell](https://shell.azure.com/)).

    ```shell
    az login
    az ad sp create-for-rbac -n "<Unique SP Name>" --role contributor
    ```

    For example:

    ```shell
    az ad sp create-for-rbac -n "http://AzureArcAro" --role contributor
    ```

    Output should look like this:

    ```json
    {
    "appId": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "displayName": "AzureArcAro",
    "name": "http://AzureArcAro",
    "password": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "tenant": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    }
    ```

    > **Note: The Jumpstart scenarios are designed with as much ease of use in-mind and adhering to security-related best practices whenever possible. It is optional but highly recommended to scope the service principal to a specific [Azure subscription and resource group](https://docs.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest) as well considering using a [less privileged service principal account](https://docs.microsoft.com/en-us/azure/role-based-access-control/best-practices)**

- [Enable subscription with](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types#register-resource-provider) the resource providers for Azure Arc-enabled Kubernetes and Azure Red Hat OpenShift. Registration is an asynchronous process, and registration may take approximately 10 minutes.

  ```shell
  az provider register --namespace Microsoft.Kubernetes
  az provider register --namespace Microsoft.KubernetesConfiguration
  az provider register --namespace Microsoft.ExtendedLocation
  az provider register --namespace Microsoft.RedHatOpenShift
  ```

  You can monitor the registration process with the following commands:

  ```shell
  az provider show -n Microsoft.Kubernetes -o table
  az provider show -n Microsoft.KubernetesConfiguration -o table
  az provider show -n Microsoft.ExtendedLocation -o table
  az provider show -n Microsoft.RedHatOpenShift -o table
  ```
- Check your subscription quota for the DSv3 family.

    > **Note: Azure Red Hat OpenShift requires a minimum of 40 cores to create and run an OpenShift cluster.**

  ```shell
  LOCATION=eastus
  az vm list-usage -l $LOCATION --query "[?contains(name.value, 'standardDSv3Family')]" -o table

- Get the Azure Red Hat OpenShift resource provider Id which needs to be assigned with the “Contributor” role.

  ```shell
  az ad sp list --filter "displayname eq 'Azure Red Hat OpenShift RP'" --query "[?appDisplayName=='Azure Red Hat OpenShift RP'].{name: appDisplayName, objectId: objectId}"
  ```

  ![Screenshot of Azure resource provider for Aro](./01.png)

## Deployment

- The deployment is using the template parameters file. Before initiating the deployment, edit the [*azuredeploy.parameters.json*](https://github.com/microsoft/azure_arc/blob/main/azure_arc_k8s_jumpstart/aro/arm_template/azuredeploy.parameters.json) file to match your environment.

  ![Screenshot of Azure ARM template](./02.png)

  To deploy the ARM template, navigate to the [deployment folder](https://github.com/microsoft/azure_arc/tree/main/azure_arc_k8s_jumpstart/aro/arm_template) and run the below command:

  ```shell
  az group create --name <Name of the Azure resource group> --location <Azure Region>
  az deployment group create \
  --resource-group <Name of the Azure resource group> \
  --name <The name of this deployment> \
  --template-uri https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_k8s_jumpstart/aro/arm_template/azuredeploy.json \
  --parameters <The *azuredeploy.parameters.json* parameters file location>
  ```

  For example:

  ```shell
  az group create --name Arc-Aro-Demo --location "East US"
  az deployment group create \
  --resource-group Arc-Aro-Demo \
  --name arcarodemo01 \
  --template-uri https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_k8s_jumpstart/aro/arm_template/azuredeploy.json \
  --parameters azuredeploy.parameters.json
  ```

    > **Note: It normally takes about 35 minutes to create a cluster..**

- Once the ARM template deployment is completed, a new Azure Red Hat OpenShift cluster in a new Azure resource group is created.

  ![Screenshot of Azure Portal showing Aro resource](./03.png)

  ![Screenshot of Azure Portal showing Aro resource](./04.png)

## Connecting to Azure Arc

- Now that you have a running Azure Red Hat OpenShift cluster, edit the environment variables section in the included [az_connect_aro](https://github.com/microsoft/azure_arc/blob/main/azure_arc_k8s_jumpstart/aro/arm_template/scripts/az_connect_aro.sh) shell script.

  ![Screenshot of az_connect_aro shell script](./05.png)

- In order to keep your local environment clean and untouched, we will use [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) (located in the top-right corner in the Azure portal) to run the *az_connect_aro* shell script against the Aro cluster. **Make sure Cloud Shell is configured to use Bash.**

  ![Screenshot of Azure Cloud Shell button in Visual Studio Code](./06.png)

- After editing the environment variables in the [*az_connect_aro*](https://github.com/microsoft/azure_arc/blob/main/azure_arc_k8s_jumpstart/aro/arm_template/scripts/az_connect_aro.sh) shell script to match your parameters, save the file and then upload it to the Cloud Shell environment and run it using the ```. ./az_connect_aro.sh``` command.

  > **Note: The extra dot is due to the script having an *export* function and needs to have the vars exported in the same shell session as the other commands.**

  ![Screenshot showing upload of file to Cloud Shell](./07.png)

  ![Screenshot showing upload of file to Cloud Shell](./08.png)

- Once the script run has finished, the Aro cluster will be projected as a new Azure Arc cluster resource.

  ![Screenshot showing Azure Portal with Azure Arc-enabled Kubernetes resource](./09.png)

  ![Screenshot showing Azure Portal with Azure Arc-enabled Kubernetes resource](./10.png)

  ![Screenshot showing Azure Portal with Azure Arc-enabled Kubernetes resource](./11.png)

## Delete the deployment

The most straightforward way is to delete the Azure Arc cluster resource via the Azure Portal, just select the cluster and delete it.

![Screenshot showing how to delete Azure Arc-enabled Kubernetes resource](./12.png)

If you want to nuke the entire environment, run the below commands.

```shell
az deployment group delete --name <Deployment name> --resource-group <Azure resource group name>
```

```shell
az group delete --name <Azure resource group name> --yes
```

For example:

```shell
az deployment group delete --name arcarodemo01 --resource-group Arc-Aro-Demo
```

```shell
az group delete --name Arc-Aro-Demo --yes
```
