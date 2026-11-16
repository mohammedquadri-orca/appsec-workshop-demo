# Module calls – these show up as the module chain in Orca Cloud-to-Dev
# (S3 bucket asset -> module.storage -> infra/modules/storage/main.tf).

module "storage" {
  source = "./modules/storage"

  bucket_prefix = "${var.name}-data-"
  # ORCA-DEMO: IaC – data bucket created WITHOUT server-side encryption configuration
  encryption_enabled = false
}

module "storage_reports" {
  source = "./modules/storage"

  bucket_prefix = "${var.name}-reports-"
  # ORCA-DEMO: IaC (PR) – encryption DISABLED on the reports bucket
  encryption_enabled = false
}
