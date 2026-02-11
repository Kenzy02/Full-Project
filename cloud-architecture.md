# Cloud Architecture: EKS Migration

This document visualizes the production-grade architecture built on AWS EKS. It highlights the networking, storage, security, and backup strategies implemented during the migration.

## 🏗️ Architecture Diagram

```mermaid
graph TD
    subgraph Internet
        User((User Browser))
    end

    subgraph AWS_Cloud ["AWS Cloud (us-east-1)"]
        subgraph VPC ["VPC (10.0.0.0/16)"]
            IGW[Internet Gateway]
            
            subgraph Public_Subnets ["Public Subnets (Tier: Public)"]
                ALB[[AWS Application Load Balancer]]
                NAT[NAT Gateways]
            end

            subgraph Private_Subnets ["Private Subnets (Tier: Private)"]
                subgraph EKS_Nodes ["EKS Managed Node Group"]
                    subgraph Pods_Frontend [Namespace: pro-fe]
                        FE1[Frontend Pod]
                        FE2[Frontend Pod]
                        FE3[Frontend Pod]
                    end
                    
                    subgraph Pods_Backend [Namespace: pro-be]
                        BE1[Backend Pod]
                        BE2[Backend Pod]
                        BE3[Backend Pod]
                    end
                    
                    subgraph Pods_DB [Namespace: pro-db]
                        DB_SS[PostgreSQL StatefulSet]
                        DB1[(Postgres Pod 0)]
                        DB2[(Postgres Pod 1)]
                    end

                    subgraph Controllers [Namespace: kube-system]
                        LBC[AWS Load Balancer Controller]
                        EBS_CSI[EBS CSI Driver]
                    end

                    subgraph Backups [Namespace: velero]
                        VELERO[Velero Server]
                    end
                end
            end
        end

        subgraph External_Services ["AWS Managed Services"]
            ACM[ACM: SSL/TLS Certificates]
            EBS_VOL[(AWS EBS gp3 Volumes)]
            S3_BACKUP[S3: Velero Backups]
            S3_TF[S3: Terraform State]
        end
    end

    %% Communication Flow
    User -- "HTTPS (443)" --> ALB
    ALB -- "SSL Termination (ACM)" --> ACM
    ALB -- "Route Traffic" --> FE1 & FE2 & FE3
    FE1 & FE2 & FE3 -- "API Requests" --> BE1 & BE2 & BE3
    BE1 & BE2 & BE3 -- "SQL Connection" --> DB_SS
    DB_SS -- "Stateful Storage" --> DB1 & DB2
    
    %% Infrastructure Management
    DB1 & DB2 -- "Read/Write" --> EBS_VOL
    EBS_CSI -- "Manage" --> EBS_VOL
    VELERO -- "Snapshots & Metadata" --> S3_BACKUP
    NAT -- "Outbound Traffic" --> IGW
    IGW -- "Internet" --> Internet
```

---

## 🛠️ Components Breakdown

### 1. Networking (VPC)
*   **Multi-AZ Deployment**: Resources are spread across `us-east-1a`, `us-east-1b`, and `us-east-1c` for high availability.
*   **Subnet Isolation**: 
    *   **Public**: Hosts the Application Load Balancer (ALB) and NAT Gateways.
    *   **Private**: Hosts the EKS Worker Nodes. Workloads are not directly reachable from the internet, increasing security.

### 2. Compute (EKS)
*   **Control Plane**: Managed by AWS (v1.30).
*   **Data Plane**: Managed Node Group (`general`) using `t3.medium` instances with auto-scaling (min: 1, max: 3).

### 3. Traffic Management (Ingress)
*   **AWS Load Balancer Controller**: Provisions an Application Load Balancer (ALB) dynamically based on Kubernetes Ingress resources.
*   **Security (SSL/TLS)**: SSL termination is handled at the ALB using **AWS Certificate Manager (ACM)**.
*   **HTTPS Redirect**: All port 80 (HTTP) traffic is automatically redirected to port 443 (HTTPS).

### 4. Database & Storage (StatefulSet)
*   **StatefulSet**: PostgreSQL runs with 2 replicas, ensuring stable network identities and persistent storage binding.
*   **Dynamic Provisioning**: Using the **EBS CSI Driver**, Kubernetes automatically requests and attaches **gp3 EBS volumes** to database pods.

### 5. Disaster Recovery (Velero)
*   **Cloud-Native Backups**: Velero is installed to perform scheduled backups of all Kubernetes resources and EBS snapshots.
*   **Off-site Storage**: Backups are stored in a dedicated **S3 bucket** (`kenzy-velero-backups`), protecting data even if the cluster is deleted.

### 6. Security (IAM & OIDC)
*   **OIDC Provider**: Integrated with EKS to enable **IAM Roles for Service Accounts (IRSA)**.
*   **Least Privilege**: The ALB Controller and Velero have specific IAM roles that grant them only the AWS permissions they need.
