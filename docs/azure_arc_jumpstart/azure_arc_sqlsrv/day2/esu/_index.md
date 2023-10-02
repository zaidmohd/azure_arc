---
type: docs
title: "Using Azure Arc-enabled SQL Server to deliver Extended Security Updates SQL Server 2012"
linkTitle: "Using Azure Arc-enabled SQL servers to deliver Extended Security Updates SQL Server 2012"
weight: 1
description: >
---

## Using Azure Arc-enabled SQL Server to deliver Extended Security Updates SQL Server 2012

This Jumpstart scenario leverages the automation found on "Using Azure Arc to deliver Extended Security Updates for Windows Server and SQL Server 2012", follow the guide and automation under Azure Arc-enabled servers choosing to deploy either only SQL Server or both SQL and Windows Server, to do that make sure to set up the parameters as follows:

- _`spnClientId`_: the AppId of the service principal you created before.
- _`spnClientSecret`_the password of the service principal you created before.
- _`spnTenantId`_: your Azure AD's tenant ID.
- _`windowsAdminUsername`_: Windows admin username for your Azure VM.
- _`windowsAdminPassword`_: password for the Windows admin username.
- _`deployBastion`_: whether or not you'd like to deploy Azure Bastion to access the Azure VM. Values can be "true" or "false"
- _`esu`_: this variable will allow you to control what VMs will be deployed. It can be`_:
  - _`ws`_: to only deploy a Windows Server 2012 VM that will be registered as an Arc-enabled server.
  - _`sql`_: to only deploy a SQL Server 2012 VM that will be registered as an Arc-enabled SQL server.
  - _`both`_: to deploy both a Windows Server 2012 VM and a SQL Server 2012 VM that will be Arc enabled.

 > **NOTE: Set the esu parameter to either "sql" or "both" for ESU on SQL Server**

**NOTE: this scenario will not provide or create ESU licenses, you will need to provisioned them separately. The scenario will however create Windows Server 2012 R2 and/or SQL Server 2012 machines connected to Azure Arc that you will be able to enroll on Extended Security Updates via the Azure portal and you'll be billed monthly via your Azure subscription.**