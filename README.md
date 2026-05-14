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
