# Enterprise Azure Disaster Recovery (DR) Project

## Project Overview
This project demonstrates the design and implementation of a highly available, multi-region web application on Microsoft Azure. The architecture is specifically designed to survive a total regional failure (Disaster Recovery) by automatically routing traffic and failing over to a secondary region with zero data loss and minimal downtime.

---

## Architecture Components

1. **Frontend / API Layer:** Node.js Express Application
2. **Compute:** Azure App Service (Web Apps)
3. **Database:** Azure SQL Database
4. **Global Routing:** Azure Traffic Manager
5. **Observability:** Azure Monitor & Application Insights

---

## Implementation 2: VM-Based Disaster Recovery Using Azure Site Recovery

This project also includes an alternate disaster recovery architecture using Azure Site Recovery (ASR) to protect and fail over virtual machine workloads.

### Key components

- **Primary Compute:** Azure Virtual Machines in the primary region running the same application stack.
- **Secondary Recovery Region:** Azure Virtual Machines in a paired secondary region configured as the ASR recovery target.
- **Replication Service:** Azure Site Recovery replicates VM disks continuously from the primary region to the secondary region.
- **Networking:** Azure Virtual Network peering and recovery network configuration to ensure the recovered VMs can communicate with dependent services.
- **Failover Control:** ASR Recovery Plans orchestrate shutdown, failover, and boot order for multi-VM applications.
- **Traffic Failover:** Azure Traffic Manager or Azure Front Door redirects user traffic to the recovered VMs after ASR initiates failover.

### VM-based DR workflow

1. Provision the application on Azure VMs in the primary region.
2. Enable Azure Site Recovery on the VM resource group and configure the secondary region as the recovery site.
3. Configure replication policy settings for RPO, recovery point retention, and application-consistent snapshots.
4. Create an ASR Recovery Plan that defines the failover order for web, app, and database tier VMs.
5. Test the recovery plan with a planned/test failover to validate the secondary environment without impacting production.
6. During an outage, trigger ASR failover to bring the secondary VMs online and update the traffic routing endpoint.
7. After recovery, execute failback or reverse replication once the primary region is restored.

### Benefits of VM-Based ASR DR

- Provides enterprise-grade protection for legacy or stateful workloads that are not easily migrated to PaaS.
- Supports application-consistent recovery points and orchestrated failover for multi-VM applications.
- Simplifies disaster recovery operations by centralizing failover management in Azure Site Recovery.
- Enables failback to the primary region once the outage is remediated.

### Sample ASR setup

A companion PowerShell script is included in `asr-site-recovery-setup.ps1` to provision the Recovery Services vault and enable Azure VM replication.

```powershell
.\asr-site-recovery-setup.ps1 \
  -SubscriptionId "<your-subscription-id>" \
  -PrimaryResourceGroup "dr-primary-rg" \
  -RecoveryResourceGroup "dr-secondary-rg" \
  -VaultName "dr-asr-vault" \
  -VaultLocation "centralindia" \
  -PrimaryVmName "dr-primary-vm" \
  -PrimaryVmResourceGroup "dr-primary-rg" \
  -RecoveryVmResourceGroup "dr-secondary-rg" \
  -RecoveryFabricName "DRSecondaryFabric"
```

Customize the parameters to match your environment, then run the script from an Azure PowerShell session.

#### Azure CLI alternative

```bash
az login
az account set --subscription "<your-subscription-id>"

az group create --name dr-primary-rg --location centralindia
az group create --name dr-secondary-rg --location southindia

az provider register --namespace Microsoft.RecoveryServices

az recoveryservices vault create \
  --resource-group dr-primary-rg \
  --name dr-asr-vault \
  --location centralindia

az recoveryservices vault backup-properties set \
  --resource-group dr-primary-rg \
  --vault-name dr-asr-vault \
  --storage-model GeoRedundant

# Use Azure Portal or ASR PowerShell/CLI extension to enable replication for the VM.
```

A sample CLI script is also included in `asr-site-recovery-setup-cli.sh` for vault and resource group provisioning.

### Implementation 2: VM-Based ASR Step-by-Step

1. Provision your primary VM workloads in the primary region and install the application stack.
2. Create a separate recovery resource group in the paired secondary region.
3. Provision an Azure Recovery Services vault in the primary region and register the vault with the `Microsoft.RecoveryServices` provider.
4. Enable ASR replication for the primary VMs, selecting the secondary region as the target.
5. Configure a replication policy with the required RPO, application-consistent snapshot frequency, and retention settings.
6. Create an ASR Recovery Plan to define boot order and orchestration for all protected VMs.
7. Perform a test failover to validate the secondary environment and confirm network/DNS connectivity.
8. During a disaster, trigger the failover and update Traffic Manager or Front Door to point to the recovered VM endpoints.
9. After the primary region is restored, execute failback or reverse replication to resume normal operation.

The goal is to validate the complete VM-based DR path and ensure the recovery environment is ready before an actual outage.

---

## Step-by-Step Implementation

### 1. Application Development
- Developed a lightweight, stateless Node.js Express application.
- Configured health check routes (`/health`) specifically designed for load balancer probing.

### 2. Multi-Region Compute Deployment
- **Primary Region (Central India):** Deployed the application to `passprimarydemoapp`.
- **Secondary Region (South/Canada Central):** Deployed an identical copy of the application to `webappsecondary` to serve as a hot standby.

### 3. Database High Availability & Geo-Replication
- **Primary SQL Server:** Created `paas-primary-sql` in Central India hosting the `paas-primary-db` database.
- **Firewall Rules:** Configured secure access allowing only Azure internal services to communicate with the database.
- **Geo-Replication:** Created a secondary SQL server (`paas-secondary-sql`) in South India and established continuous asynchronous Geo-Replication. This ensures that if Central India goes completely offline, a replica of the data is safely preserved and accessible in South India.

### 4. Global Traffic Management
- Deployed an **Azure Traffic Manager** profile (`paasdrdemo.trafficmanager.net`) configured with **Priority Routing**.
- **Endpoint 1 (Priority 1):** The primary web app. Receives 100% of user traffic during normal operations.
- **Endpoint 2 (Priority 2):** The secondary web app. Sits in standby, receiving traffic *only* if the primary region goes offline.
- **Health Probes:** Configured Traffic Manager to constantly ping the `/health` endpoint. If the primary app fails to return a `200 OK` status, Traffic Manager automatically redirects all new DNS requests to the secondary region.

### 5. Enterprise Monitoring & Alerting
- **Telemetry:** Provisioned an Azure Log Analytics Workspace and Application Insights, dynamically linking both web apps to track latency, request rates, and failures in real-time.
- **Action Groups:** Created an Action Group (`DRAlerts`) configured to alert administrators via email.
- **Automated Alerts:** Set up automated Azure Monitor Metric Alerts (e.g., triggering an email if the primary app experiences a spike in HTTP 500 Internal Server Errors).

### 6. Disaster Recovery Drill (The Test)
To prove the architecture's resilience, we performed a live DR Drill:
1. **Triggered a "Disaster":** Manually stopped the primary App Service (`passprimarydemoapp`) to simulate a regional outage.
2. **Observation:** Traffic Manager's health probes detected the failure.
3. **Automated Failover:** Traffic Manager automatically began resolving DNS requests for `paasdrdemo.trafficmanager.net` to the secondary region (`webappsecondary`).
4. **Result:** End-users continued to experience uninterrupted service, successfully proving the Business Continuity and Disaster Recovery (BCDR) strategy.

---

## Key Learnings & Takeaways
- **DNS Propagation:** DNS caching at the client/browser level plays a huge role in RTO (Recovery Time Objective). Clearing the cache (`ipconfig /flushdns`) or lowering the TTL (Time To Live) is critical for fast failovers.
- **Cloud-Native DR:** Relying on PaaS (Platform as a Service) features like Azure SQL Geo-Replication and Azure Traffic Manager significantly reduces the operational overhead of maintaining a DR site compared to traditional infrastructure.
