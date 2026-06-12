# Lab Guide — Deploying & Verifying the AZ-104 Infrastructure

This is the runbook. Follow it top to bottom. Total Azure cost if you tear down
the same day: a few cents.

---

## 0. Prerequisites (one-time)

1. **An Azure subscription.** Use [Azure for Students](https://azure.microsoft.com/free/students/)
   — $100 credit, no credit card. A student email gets you in.
2. **Azure CLI** installed: [install guide](https://learn.microsoft.com/cli/azure/install-azure-cli).
3. **Bicep** (bundled with the CLI): `az bicep install`
4. **An SSH key for the lab:**
   ```bash
   ssh-keygen -t ed25519 -f $HOME/.ssh/az104_lab -C az104-lab
   ```
   This creates `az104_lab` (private) and `az104_lab.pub` (public). The deploy
   script reads the `.pub` file.
5. **Sign in:**
   ```bash
   az login
   az account show --output table   # confirm the right subscription is active
   ```

---

## 1. Validate the templates before deploying

This is itself an AZ-104 skill — never deploy unverified IaC.

```bash
az bicep build --file infra/main.bicep
```

No output = it compiled cleanly. **Screenshot this.**

---

## 2. Deploy

```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

The script detects your public IP, creates the resource group, and deploys the
VNet, NSGs, VM, public IP, and storage account. Takes about 3–5 minutes.

When it finishes it prints outputs including `webServerUrl`. **Screenshot the
deployment outputs.**

---

## 3. Verify it actually works

1. **Web tier:** open the `webServerUrl` in a browser. You should see the lab
   page served by nginx. **Screenshot the page + the URL bar.**
2. **SSH (locked to your IP):**
   ```bash
   ssh -i $HOME/.ssh/az104_lab azureadmin@<public-ip>
   ```
   You're in. **Screenshot the terminal session.**
3. **Network segmentation:** in the portal, open `vnet-az104-lab` → Subnets and
   show both subnets each bound to their NSG. Open `nsg-data` and show the
   "Deny-Internet-Inbound" rule. **Screenshot both.**

---

## 4. The admin tasks Bicep doesn't cover

These hit AZ-104 exam domains the IaC alone doesn't show. Do them in the portal
or CLI, screenshot each.

### 4a. RBAC (Identity & governance)
Assign a scoped, least-privilege role. Example — grant Reader at the resource
group scope to a user or group:
```bash
RG_ID=$(az group show --name rg-az104-lab --query id -o tsv)
az role assignment create \
  --assignee "<user-or-group-object-id>" \
  --role "Reader" \
  --scope "$RG_ID"
```
Then `az role assignment list --scope "$RG_ID" -o table`. **Screenshot the list.**
Talking point: *why Reader at RG scope, not Contributor at subscription scope.*

### 4b. Resource lock (Governance)
Protect the group from accidental deletion:
```bash
az lock create --name lock-no-delete \
  --lock-type CanNotDelete \
  --resource-group rg-az104-lab
```
**Screenshot** the lock in the portal (Resource group → Locks).
> Remove it before teardown: `az lock delete --name lock-no-delete --resource-group rg-az104-lab`

### 4c. Monitoring & alerts
Create a CPU alert on the VM:
```bash
VM_ID=$(az vm show -g rg-az104-lab -n vm-web-01 --query id -o tsv)
az monitor metrics alert create \
  --name "vm-high-cpu" \
  --resource-group rg-az104-lab \
  --scopes "$VM_ID" \
  --condition "avg Percentage CPU > 80" \
  --description "Alert when web VM CPU exceeds 80%"
```
**Screenshot** the alert rule. Talking point: *what you'd wire the action group to.*

---

## 5. Capture your screenshots

Drop everything into `docs/screenshots/` and reference them in the README. The
screenshots are what make this a portfolio piece instead of a code dump — they
prove *you ran it*, not just wrote it.

Minimum set:
- [ ] `bicep build` clean compile
- [ ] Deployment outputs
- [ ] nginx lab page in browser
- [ ] SSH session
- [ ] VNet subnets + NSG rules
- [ ] RBAC assignment list
- [ ] Resource lock
- [ ] CPU alert rule

---

## 6. Tear down (do this when you're done)

```bash
# remove the lock first if you created one
az lock delete --name lock-no-delete --resource-group rg-az104-lab || true
./scripts/teardown.sh
```

Confirm in the portal that `rg-az104-lab` is gone. Now it costs nothing.

---

## What to be ready to explain in an interview

- Why SSH is scoped to one IP and HTTP is open to the internet.
- Why the data subnet denies inbound internet traffic but allows the web subnet.
- Why SSH-key auth with password auth disabled.
- Why tags + a resource lock matter for governance at scale.
- What you'd change to make this production-grade (Bastion instead of public SSH,
  private endpoints, a load balancer + scale set, Key Vault for secrets).

If you can talk through those, this project does its job.
