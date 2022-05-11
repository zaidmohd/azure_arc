---
type: docs
title: "SQL Managed Instance Active Directory Authentication ARM Template"
linkTitle: "SQL Managed Instance Active Directory Authentication ARM Template"
weight: 2
description: >
---
## Prerequisites

- Complete jump start scenario documented at [SQL Managed Instance ARM Template](../aks_mssql_mi_arm_template/_index.md)
- Create subnet for domain controller and client VM to configure and test AD authentication.

## Deploy Active Directory Domain Controller

- Deploy virtual machine with Standard_D2s_v3 size to support Active Directory domain controller.
- Select a domain name to promote VM as domain controller.
- Install DNS server role and create a zone that matches selected domain name.
- Configure DNS forwarder to Azure DNS IP address to resolve Azure and other public DNS names.
- Promote VM as a domain controller using the domain name selected.
- Enable reverse DNS lookup for domain controller
- Update VNet DNS servers with domain control VM private IP from the subnet.
- Update AKS VM scale sets to use updated DNS entries.

## Update Azure Arc SQL MI to use AD authentication

- Choose FQDN name for SQL MI to create SPNs, DNS registration, and create key tab file.
- Create user account to generate key tab file.
- Use auto generate key table option or manual steps to create key tab file.
- Create k8s secret with base64 encoded key tab data
- Create AD connector YAML file with domain controller details and deploy AD connector pods.
- Update SQL MI instance to use key tab file and DNS information to enable SQL authentication.

## Deploy Client VM and join to domain controller

## Connect to client VM using domain credentials
