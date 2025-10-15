# 🚀 Terraform EKS Infrastructure (Zurich Region)

## 🧭 Overview

This project provisions complete **Amazon EKS clusters** in the **Zurich (eu-central-2)** region for multiple environments:
- `dev`
- `test`
- `prod`

Each environment includes:
- 🧱 A dedicated VPC with unique CIDR
- 🌐 Public and Private subnets (3x each)
- 🛰️ Internet Gateway and NAT Gateway
- ☸️ EKS cluster and node groups
- 🔐 IAM roles and security configurations

All environments share a **central Terraform remote backend** for state management.

---

## 📂 Project Structure

