# =====================================================================
# 💾 Terraform Backend Configuration — Test
# =====================================================================

terraform {
  backend "s3" {
    bucket         = "experts-lab-terraform-states"
    key            = "eks/test/terraform.tfstate"
    region         = "eu-central-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
