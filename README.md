# Azure Infrastructure-as-Code — AZ-104 (Bicep)

Infrastructure-as-Code (Bicep) that defines a segmented, secured two-tier Azure environment. Written to demonstrate AZ-104 Azure Administrator skills through clean, modular IaC.

Backs my **AZ-104 (Azure Administrator Associate)** knowledge — the Bicep implements the core admin domains (networking, compute, storage, identity, governance) as working, deployable templates.

---

## What the Bicep provisions

When deployed, the templates create a resource group containing:

- **Virtual network** (`10.0.0.0/16`) split into a public **web subnet** and a private **data subnet**.
- **Two NSGs** with least-privilege rules: the web tier allows HTTP from the internet and SSH **only from a single admin IP**; the data tier denies inbound internet traffic and accepts traffic only from the web subnet.
- **Ubuntu web VM** (`Standard_B1s`) with a Standard public IP, SSH-key auth (password login disabled), and nginx via cloud-init.
- **Secure storage account** (StorageV2, HTTPS-only, TLS 1.2 min, public blob access disabled) with a private container.
- Consistent **tags** across every resource for governance.

All defined in modular Bicep, deployable with a single script.

```
.
├── infra/
│   ├── main.bicep          # orchestrator
│   ├── network.bicep       # VNet, subnets, NSGs
│   ├── compute.bicep       # public IP, NIC, Ubuntu VM (SSH key, nginx)
│   ├── storage.bicep       # secure StorageV2 account + private container
│   └── cloud-init.yaml     # installs nginx, serves a landing page
├── scripts/
│   ├── deploy.sh           # detect IP, create RG, deploy
│   └── teardown.sh         # delete everything
├── LAB-GUIDE.md            # full step-by-step deployment runbook
└── README.md
```

---

## How it maps to the AZ-104 exam domains

| AZ-104 domain | Implemented by |
|---|---|
| Identity & governance | RBAC role assignment at RG scope, resource lock, tagging strategy |
| Storage | Secure StorageV2 account, private container, TLS/HTTPS enforcement |
| Compute | Ubuntu VM, managed disk, SSH-key auth, cloud-init provisioning |
| Virtual networking | VNet, subnetting, NSGs, least-privilege rules, public IP |
| Monitoring | Metric alert on VM CPU |
| IaC & tooling | Modular Bicep, `az bicep build` validation, CLI deployment |

---

## Deploy it

Full runbook in **[LAB-GUIDE.md](LAB-GUIDE.md)**. Short version:

```bash
ssh-keygen -t ed25519 -f $HOME/.ssh/az104_lab -C az104-lab
az login
az bicep build --file infra/main.bicep   # validate
./scripts/deploy.sh                       # deploy
./scripts/teardown.sh                     # clean up
```

Deployable on Azure for Students free credit; tear-down brings cost to near zero.

---

## Design notes & production gaps (intentional)

Kept deliberately small and cheap. For production I'd swap public SSH for **Azure Bastion**, put the storage and data tier behind **private endpoints**, front the web tier with a **load balancer + VM scale set**, and move secrets into **Key Vault**.

---

**Author:** Kumail Janjua
