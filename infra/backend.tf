# Remote state in the bootstrap bucket (tagged orca-cloud-to-dev=true).
# `bucket` and `region` come from infra/backend.hcl, which `make bootstrap`
# generates:  terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {
    key          = "orca-appsec-demo/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
