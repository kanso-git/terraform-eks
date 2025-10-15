Excellent request 👏 — you’ve gone through a **complete professional Terraform lifecycle**, and documenting it properly is exactly what a good DevOps/SRE would do.

Below is a **ready-to-use Markdown documentation** that you can commit as `TERRAFORM_WORKFLOW.md` (or `terraform-usage-guide.md`).
It covers every step and command used throughout your full journey — from initializing your `dev` environment, configuring backends, planning, applying, validating, reconfiguring, and safely destroying.

---

# 🌍 **Terraform Workflow Guide — Multi-Environment Setup**

> **Project:** AWS EKS Infrastructure (Dev / Test / Prod Environments)
> **Environment Example:** `dev`
> **Modules Used:** `vpc`, `iam`, `eks`, `global`
> **Backend:** S3 (remote state)
> **Tools:** Terraform CLI, AWS CLI

---

## 📘 Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Initialization](#1-initialization)
4. [Validation](#2-validation)
5. [Planning](#3-planning)
6. [Applying Changes](#4-apply--deploy)
7. [Reconfiguring Backend](#5-reconfigure-backend)
8. [Destroying Infrastructure](#6-destroy)
9. [Troubleshooting Commands](#7-troubleshooting--useful-commands)
10. [Best Practices](#8-best-practices)

---

## 🧭 **Overview**

This document explains the full **Terraform workflow** for managing a multi-environment AWS infrastructure.
Each environment (`dev`, `test`, `prod`) has its own isolated configuration under the `/envs` directory.

Terraform interacts with:

* **S3 Backend** — to store remote state files
* **DynamoDB Table** — for state locking (to prevent concurrent changes)
* **AWS Providers** — to manage cloud resources

---

## 🗂️ **Directory Structure**

Example:

```
terraform/
├── bootstrap-terraform.sh
├── global/
│   ├── provider.tf
│   ├── variables.tf
│   └── versions.tf
├── modules/
│   ├── vpc/
│   ├── eks/
│   └── iam/
└── envs/
    ├── dev/
    │   ├── backend.conf
    │   ├── backend.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   └── dev.tfvars
```

---

## ⚙️ **1. Initialization**

### 🧩 Purpose:

Initializes Terraform in the `dev` environment, downloads required providers, and configures the backend.

### 🔧 Command:

```bash
terraform init -backend-config=backend.conf -reconfigure
```

### 💬 Explanation:

| Option                         | Description                                                                  |
| ------------------------------ | ---------------------------------------------------------------------------- |
| `init`                         | Prepares Terraform to work with your configuration.                          |
| `-backend-config=backend.conf` | Loads S3 backend configuration (bucket, region, key).                        |
| `-reconfigure`                 | Forces Terraform to reinitialize the backend if it was changed or corrupted. |

### ✅ Example Output:

```
Successfully configured the backend "s3"!
Terraform has been successfully initialized!
```

---

## ✅ **2. Validation**

### 🧩 Purpose:

Ensures your Terraform syntax and configuration are valid before running any actions.

### 🔧 Command:

```bash
terraform validate
```

### 💬 Explanation:

Checks:

* HCL syntax correctness
* Module structure
* Provider and variable definitions

### ✅ Example Output:

```
Success! The configuration is valid.
```

---

## 🧮 **3. Planning**

### 🧩 Purpose:

Previews what Terraform will create, change, or destroy.

### 🔧 Command:

```bash
terraform plan -var-file="dev.tfvars"
```

### 💬 Explanation:

| Option      | Description                                            |
| ----------- | ------------------------------------------------------ |
| `plan`      | Simulates the apply process without executing changes. |
| `-var-file` | Injects environment-specific variables.                |

### ✅ Example Output:

```
Plan: 18 to add, 0 to change, 0 to destroy.
```

---

## 🚀 **4. Apply / Deploy**

### 🧩 Purpose:

Actually applies all infrastructure changes defined in the Terraform configuration.

### 🔧 Command:

```bash
terraform apply -var-file="dev.tfvars"
```

### 💬 Explanation:

Executes the changes planned in the previous step.

Terraform will display a plan summary and ask for confirmation:

```
Do you want to perform these actions?
  Only 'yes' will be accepted to approve.
  Enter a value:
```

Type:

```bash
yes
```

### ✅ Example Output:

```
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.
```

---

## 🧱 **5. Reconfigure Backend**

### 🧩 Purpose:

Reinitialize the backend (S3 remote state) when backend settings change or when cloning a new workspace.

### 🔧 Command:

```bash
terraform init -backend-config=backend.conf -reconfigure
```

### 💬 Typical Use Cases:

* You modified `backend.conf`
* You cloned the project to a new system
* You switched to a new environment (test/prod)

### 📄 Example `backend.conf`:

```hcl
bucket         = "experts-lab-terraform-states"
key            = "eks/dev/terraform.tfstate"
region         = "eu-central-2"
encrypt        = true
dynamodb_table = "terraform-locks"
```

---

## 💣 **6. Destroy**

### 🧩 Purpose:

Safely destroy all resources created by Terraform in the `dev` environment.

### 🔧 Command:

```bash
terraform destroy -var-file="dev.tfvars"
```

### 💬 Explanation:

| Option      | Description                                                           |
| ----------- | --------------------------------------------------------------------- |
| `destroy`   | Deletes all resources defined in the current Terraform configuration. |
| `-var-file` | Ensures destruction applies only to the `dev` environment.            |

### 🧠 Tip:

You can preview before destroying with:

```bash
terraform plan -destroy -var-file="dev.tfvars"
```

### ⚠️ Warning:

This will permanently delete all AWS resources (VPC, EKS, IAM, etc.) managed by this Terraform state.

---

## 🛠️ **7. Troubleshooting & Useful Commands**

| Command                         | Description                                                     |
| ------------------------------- | --------------------------------------------------------------- |
| `terraform fmt`                 | Formats Terraform files for consistent indentation and style.   |
| `terraform providers`           | Lists all used providers and their versions.                    |
| `terraform output`              | Displays values exported by modules (e.g., VPC ID, subnet IDs). |
| `terraform show`                | Shows the current state of resources in detail.                 |
| `terraform state list`          | Lists all resources tracked in the Terraform state.             |
| `terraform state rm <resource>` | Removes a resource from the state file (advanced use).          |
| `terraform graph`               | Visualizes the dependency graph of your infrastructure.         |
| `terraform workspace list`      | Lists all environment workspaces (if using workspaces).         |

---

## 🧠 **8. Best Practices**

✅ **One backend per environment**
Each environment (`dev`, `test`, `prod`) has a dedicated state file for isolation.

✅ **Version control your `.tf` files**, not the `.tfstate` files.

✅ **Always use `terraform plan`** before applying changes in production.

✅ **Tag all resources** — you already do this via `Environment`, `Owner`, `CreationDate`, `ManagedBy`.

✅ **Lock the backend** using a DynamoDB table (`terraform-locks`) to prevent concurrent state updates.

✅ **Use IAM roles created by Terraform** to maintain full infrastructure-as-code control.

✅ **Destroy safely** — only in non-production or with full backups.

---

## 🏁 **Full Lifecycle Summary**

| Phase          | Command                                                    | Purpose                          |
| -------------- | ---------------------------------------------------------- | -------------------------------- |
| 🏗️ Setup      | `terraform init -backend-config=backend.conf -reconfigure` | Initialize backend and providers |
| 🔍 Validate    | `terraform validate`                                       | Check syntax and configuration   |
| 🧩 Plan        | `terraform plan -var-file="dev.tfvars"`                    | Preview resource creation        |
| 🚀 Apply       | `terraform apply -var-file="dev.tfvars"`                   | Deploy infrastructure            |
| 🔄 Reconfigure | `terraform init -backend-config=backend.conf -reconfigure` | Reconnect to remote backend      |
| 💣 Destroy     | `terraform destroy -var-file="dev.tfvars"`                 | Delete all managed resources     |

---

## 🧾 **Optional: Clean-Up State Files**

If you fully retire an environment:

```bash
aws s3 rm s3://experts-lab-terraform-states/eks/dev/terraform.tfstate
```

To delete the DynamoDB lock (if stuck):

```bash
aws dynamodb delete-item \
  --table-name terraform-locks \
  --key '{"LockID": {"S": "eks/dev/terraform.tfstate-md5hash"}}'
```

---

## 📚 **References**

* [Terraform CLI Documentation](https://developer.hashicorp.com/terraform/cli)
* [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
* [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [AWS IAM Policies for EKS](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html)

---

Would you like me to generate this documentation as a **ready-to-download Markdown file (`terraform-usage-guide.md`)** for your repo, with proper formatting and emojis preserved?
