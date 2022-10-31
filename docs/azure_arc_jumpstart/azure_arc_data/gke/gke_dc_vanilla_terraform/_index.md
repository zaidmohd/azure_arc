---
type: docs
title: "Data Controller Terraform plan"
linkTitle: "Data Controller Terraform plan"
weight: 1
description: >
---

## Deploy an Azure Arc Data Controller (Vanilla) on GKE using Terraform

The following scenario will guide you on how to deploy a "Ready to Go" environment so you can deploy Azure Arc Data Services on a [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine) cluster using [Terraform](https://www.terraform.io/).

By the end of this scenario, you will have a GKE cluster deployed with an Azure Arc Data Controller and a Microsoft Windows Server 2022 (Datacenter) GKE compute instance VM installed and pre-configured with all the required tools needed to work with Azure Arc Data Services:

![Deployed Architecture](./01.png)

> **NOTE: Currently, Azure Arc-enabled data services with PostgreSQL is in [public preview](https://docs.microsoft.com/azure/azure-arc/data/release-notes)**.

## Deployment Process Overview

- Create a Google Cloud Platform (GCP) project, IAM Role & Service Account
- Download credentials file
- Clone the Azure Arc Jumpstart repository
- Create the .tfvars file with your variables values
- Export the *TF_VAR_CL_OID* variable
- *terraform init*
- *terraform apply*
- User remotes into sidecar Windows VM, which automatically kicks off the [DataServicesLogonScript](https://github.com/microsoft/azure_arc/blob/main/azure_arc_data_jumpstart/gke/terraform/artifacts/DataServicesLogonScript.ps1) PowerShell script that deploys and configures Azure Arc-enabled data services on the GKE cluster.
- *kubectl delete namespace arc*
- *terraform destroy*

## Prerequisites

- Clone the Azure Arc Jumpstart repository

  ```shell
  git clone https://github.com/microsoft/azure_arc.git
  ```

- [Install or update Azure CLI to version 2.40.0 or higher](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest). Use the below command to check your current installed version.

  ```shell
  az --version
  ```

- Google Cloud account with billing enabled - [Create a free trial account](https://cloud.google.com/free). To create Windows Server virtual machines, you must upgraded your account to enable billing. Click Billing from the menu and then select Upgrade in the lower right.

    ![Screenshot showing how to enable billing on GCP account](./02.png)

    ![Screenshot showing how to enable billing on GCP account](./03.png)

    ![Screenshot showing how to enable billing on GCP account](./04.png)

    ***Disclaimer*** - **To prevent unexpected charges, please follow the "Delete the deployment" section at the end of this README**

- [Install Terraform 1.0 or higher](https://learn.hashicorp.com/terraform/getting-started/install.html)

- Create Azure service principal (SP). To deploy this scenario, an Azure service principal assigned with a RBAC role is required:

  - "Owner" - Required for provisioning Azure resources, interact with Azure Arc-enabled data services billing, monitoring metrics, and logs management and creating role assignment for the Monitoring Metrics Publisher role.

    To create it login to your Azure account run the below command (this can also be done in [Azure Cloud Shell](https://shell.azure.com/)).

    ```shell
    az login
    subscriptionId=$(az account show --query id --output tsv)
    SP_CLIENT_ID=$(az ad sp create-for-rbac -n "<Unique SP Name>" --role "Owner" --scopes /subscriptions/$subscriptionId --query appId -o tsv)
    SP_OID=$(az ad sp show --id $SP_CLIENT_ID --query id -o tsv)

    ```

    For example:

    ```shell
    az login
    subscriptionId=$(az account show --query id --output tsv)
    SP_CLIENT_ID=$(az ad sp create-for-rbac -n "JumpstartArcDataSvc" --role "Owner" --scopes /subscriptions/$subscriptionId --query appId -o tsv)
    ```

    Output should look like this:

    ```json
    {
    "appId": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "displayName": "JumpstartArcDataSvc",
    "password": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "tenant": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    }
    ```

    > **NOTE: The Jumpstart scenarios are designed with as much ease of use in-mind and adhering to security-related best practices whenever possible. It is optional but highly recommended to scope the service principal to a specific [Azure subscription and resource group](https://docs.microsoft.com/cli/azure/ad/sp?view=azure-cli-latest) as well considering using a [less privileged service principal account](https://docs.microsoft.com/azure/role-based-access-control/best-practices)**

- Create a new GCP Project, IAM Role & Service Account. In order to deploy resources in GCP, we will create a new GCP Project as well as a service account to allow Terraform to authenticate against GCP APIs and run the plan to deploy resources.

  - Browse to <https://console.cloud.google.com/> and login with your Google Cloud account. Once logged in, click on Select a project

    ![GCP new project](./05.png)

  - [Create a new project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) named "Azure Arc Demo".

    ![GCP new project](./05_0.png)

    ![GCP new project](./06.png)

  - After creating it, be sure to copy down the project id as it is usually different then the project name.

    ![GCP new project](./07.png)

  - Search Compute Engine API for the project

    ![Enable Compute Engine API](./08.png)

  - Enable Compute Engine API for the project

    ![Enable Compute Engine API](./09.png)

  - Create credentials for your project

    ![Add credentials](./10.png)
  
  - Create a project Owner service account credentials and download the private key JSON file and copy the file to the directory where Terraform files are located. Change the JSON file name (for example *account.json*). The Terraform plan will be using the credentials stored in this file to authenticate against your GCP project.

    ![Add credentials](./11.png)

    ![Add credentials](./12.png)

    ![Add credentials](./13.png)

    ![Add credentials](./14.png)

    ![Create private key](./15.png)

    ![Create private key](./16.png)

    ![Create private key](./17.png)

    ![Create private key](./18.png)

    ![account.json](./19.png)

  - Search Kubernetes Engine API for the project

    ![Enable the Kubernetes Engine API](./20.png)

  - Enable Kubernetes Engine API for the project

    ![Enable the Kubernetes Engine API](./21.png)

## Automation Flow

Read the below explanation to get familiar with the automation and deployment flow.

- User creates the terraform variables file (.tfvars) and export the Custom Location RP OID variable. The variable values are used throughout the deployment.

- User deploys the Terraform plan which will deploy the GKE cluster and the GCP compute instance VM as well as an Azure resource group. The Azure resource group is required to host the Azure Arc services such as the Azure Arc-enabled Kubernetes cluster, the custom location, the Azure Arc data controller, and any database services you deploy on top of the data controller.

  > **NOTE: Depending on the GCP region, make sure you do not have any [SSD quota limit in the region](https://cloud.google.com/compute/quotas), otherwise, the Azure Arc Data Controller kubernetes resources will fail to deploy.**

- As part of the Windows Server 2022 VM deployment, there are 4 script executions:

  1. *azure_arc.ps1* script will be created automatically as part of the Terraform plan runtime and is responsible on injecting the terraform variables values on to the Windows instance which will then be used in both the *ClientTools* and the *LogonScript* scripts.

  2. *password_reset.ps1* script will be created automatically as part of the Terraform plan runtime and is responsible on creating the Windows username & password.

  3. *Bootstrap.ps1* script will run at the Terraform plan runtime Runtime and will:
      - Create the *Bootstrap.log* file  
      - Install the required tools – az cli, PowerShell module, kubernetes-cli, Visual C++ Redistributable, HELM, VS Code, etc. (Chocolaty packages)
      - Download Azure Data Studio & Azure Data CLI
      - Disable Windows Server Manager, remove Internet Explorer, disable Windows Firewall
      - Download the DataServicesLogonScript.ps1 PowerShell script
      - Create the Windows schedule task to run the DataServicesLogonScript at first login

  4. *DataServicesLogonScript.ps1* script will run on user first logon to Windows and will:
      - Create the *DataServicesLogonScript.log* file
      - Install the Azure Data Studio Azure Data CLI, Azure Arc & PostgreSQL extensions
      - Create the Azure Data Studio desktop shortcut
      - Use Azure CLI to connect the GKE cluster to Azure as an Azure Arc-enabled Kubernetes cluster
      - Create a custom location for use with the Azure Arc-enabled Kubernetes cluster
      - Deploy an ARM template that will deploy the Azure Arc data controller on the GKE cluster
      - Open another Powershell session which will execute a command to watch the deployed Azure Arc Data Controller Kubernetes pods
      - Unregister the logon script Windows schedule task so it will not run after first login

## Terraform variables

- Before running the Terraform plan, create the terraform variables file (.tfvars). An example .tfvars file is located [here](https://github.com/microsoft/azure_arc/blob/main/azure_arc_data_jumpstart/gke/terraform/example/tf_variables_datacontroller_only_example.ps1)

  - *gcp_project_id*='Your GCP Project ID (Created in the prerequisites section)'
  - *gcp_credentials_filename*='Your GCP Credentials JSON filename (Created in the prerequisites section)'
  - *gcp_region*='GCP region where resource will be created'
  - *gcp_zone*='GCP zone where resource will be created'
  - *gke_cluster_name*='GKE cluster name'
  - *admin_username*='GKE cluster administrator username'
  - *admin_password*='GKE cluster administrator password'
  - *windows_username*='Windows Server Client compute instance VM administrator username'
  - *windows_password*='Windows Server Client compute instance VM administrator password' (The password must be at least 8 characters long and contain characters from three of the following four sets: uppercase letters, lowercase letters, numbers, and symbols as well as **not containing** the user's account name or parts of the user's full name that exceed two consecutive characters)
  - *SPN_CLIENT_ID*='Your Azure service principal name'
  - *SPN_CLIENT_SECRET*='Your Azure service principal password'
  - *SPN_TENANT_ID*='Your Azure tenant ID'
  - *SPN_AUTHORITY*=_https://login.microsoftonline.com_ **Do not change**
  - *AZDATA_USERNAME*='Azure Arc Data Controller admin username'
  - *AZDATA_PASSWORD*='Azure Arc Data Controller admin password' (The password must be at least 8 characters long and contain characters from the following four sets: uppercase letters, lowercase letters, numbers, and symbols)
  - *ARC_DC_NAME*='Azure Arc Data Controller name' (The name must consist of lowercase alphanumeric characters or '-', and must start and end with a alphanumeric character. This name will be used for k8s namespace as well)
  - *ARC_DC_SUBSCRIPTION*='Azure Arc Data Controller Azure subscription ID'
  - *ARC_DC_RG*='Azure resource group where all future Azure Arc resources will be deployed'
  - *ARC_DC_REGION*='Azure location where the Azure Arc Data Controller resource will be created in Azure' (Currently, supported regions supported are eastus, eastus2, centralus, westus2, westeurope, southeastasia)
  - *deploy_SQLMI*='Boolean that sets whether or not to deploy SQL Managed Instance, for this data controller only scenario we leave it set to false'
  - *SQLMIHA*='Boolean that sets whether or not to deploy SQL Managed Instance with high-availability (business continuity) configurations, for this data controller vanilla scenario we leave it set to false'
  - *deploy_PostgreSQL*='Boolean that sets whether or not to deploy PostgreSQL, for this data controller only scenario we leave it set to false'
  - *templateBaseUrl*='GitHub URL to the deployment template - filled in by default to point to [Microsoft/Azure Arc](https://github.com/microsoft/azure_arc) repository, but you can point this to your forked repo as well - e.g. `https://raw.githubusercontent.com/your--github--account/azure_arc/your--branch/azure_arc_data_jumpstart/gke/terraform/`.'
  - *MY_IP*='Your Client IP'

### Custom Location RP OID variable

- You also need to get the Custom Location RP OID to export it as an environment variable:

  > **NOTE: You need permissions to list all the service principals.**

  #### Option 1: Bash

  ```bash
  export TF_VAR_CL_OID=$(az ad sp list --all | grep '"displayName": "Custom Locations RP",' -A 2 | sed -En "s/\"id\": \"(.*)\",/\1/p")
  ```

  #### Option 2: PowerShell

  ```powershell
  $Env:TF_VAR_CL_OID=(az ad sp list --all | Select-String '"displayName": "Custom Locations RP",' -Context 0,2) -Replace '.*\s*.*\s*"id": "(.*)",\n*','$1'
  ```

## Deployment

> **NOTE: The GKE cluster will use 3 nodes of SKU "n1-standard-8".**

As mentioned, the Terraform plan and automation scripts will deploy a GKE cluster, the Azure Arc Data Controller on that cluster and a Windows Server 2022 Client GCP compute instance.

- Navigate to the folder that has Terraform binaries.

  ```shell
  cd azure_arc_data_jumpstart/gke/terraform/
  ```

- Run the ```terraform init``` command which is used to initialize a working directory containing Terraform configuration files and load the required Terraform providers.

  ![terraform init](./22.png)

- (Optional but recommended) Run the ```terraform plan -var-file="<.tfvars file name>"``` command to make sure everything is configured properly.

  ![terraform plan](./23.png)

- Run the ```terraform apply --auto-approve -var-file="<.tfvars file name>"``` command and wait for the plan to finish. **Runtime for deploying all the GCP resources for this plan is ~20-30min.**

- Once completed, you can review the GKE cluster and the worker nodes resources as well as the GCP compute instance VM created.

  ![terraform apply completed](./24.png)

  ![GKE cluster](./25.png)

  ![GKE cluster](./26.png)

  ![GCP VM instances](./27.png)

  ![GCP VM instances](./28.png)

- In the Azure Portal, a new empty Azure resource group was created which will be used for Azure Arc Data Controller and the other data services you will be deploying in the future.

  ![New empty Azure resource group](./29.png)

## Windows Login & Post Deployment

Now that we have both the GKE cluster and the Windows Server Client instance created, it is time to login to the Client VM.

- Select the Windows instance, click on the RDP dropdown and download the RDP file. Using your *windows_username* and *windows_password* credentials, log in to the VM.

  ![GCP Client VM RDP](./30.png)

  ![GCP Client VM RDP](./31.png)

- At first login, as mentioned in the "Automation Flow" section, the DataServicesLogonScript.ps1 will get executed. This script was created as part of the automated deployment process.

    Let the script run its course and **do not close** the PowerShell session, this will be done for you once completed. You will notice that the Azure Arc Data Controller gets deployed on the GKE cluster. **The logon script run time is approximately 10min long**.

    Once the script finishes, the logon script PowerShell session will be close and the Azure Arc Data Controller will be deployed on the GKE cluster and be ready to use.

  ![PowerShell login script run](./32.png)

  ![PowerShell login script run](./33.png)

  ![PowerShell login script run](./34.png)

  ![PowerShell login script run](./35.png)

  ![PowerShell login script run](./36.png)

  ![PowerShell login script run](./37.png)

  ![PowerShell login script run](./38.png)

  ![PowerShell login script run](./39.png)

  ![PowerShell login script run](./40.png)

  ![PowerShell login script run](./41.png)

  ![PowerShell login script run](./42.png)

  ![PowerShell login script run](./43.png)

  ![PowerShell login script run](./44.png)

  ![PowerShell login script run](./45.png)

  ![PowerShell login script run](./46.png)

- When the scripts are complete, all PowerShell windows will close.

  ![PowerShell login script run](./47.png)

- From Azure Portal, navigate to the resource group and confirm that the Azure Arc-enabled Kubernetes cluster, the Azure Arc data controller resource and the Custom Location resource are present.

  ![Azure Portal showing data controller resource](./48.png)

- Another tool automatically deployed is Azure Data Studio along with the *Azure Data CLI*, the *Azure Arc* and the *PostgreSQL* extensions. Using the Desktop shortcut created for you, open Azure Data Studio and click the Extensions settings to see both extensions.

  ![Azure Data Studio shortcut](./49.png)

  ![Azure Data Studio extension](./50.png)

## Delete the deployment

To completely delete the environment, follow the below steps.

- Delete the data services resources by using kubectl. Run the below command from a PowerShell window on the client VM.

  ```shell
  kubectl delete namespace arc
  ```

  ![Delete database resources](./51.png)

- Use terraform to delete all of the GCP resources as well as the Azure resource group. **The *terraform destroy* run time is approximately ~5-6min long**.

  ```shell
  terraform destroy --auto-approve
  ```

  ![terraform destroy](./52.png)

<!-- ## Known Issues -->
