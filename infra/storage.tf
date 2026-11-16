# Module calls – these show up as the module chain in Orca Cloud-to-Dev
# (S3 bucket asset -> module.storage -> infra/modules/storage/main.tf).

module "storage" {
  source = "./modules/storage"

  bucket_prefix      = "${var.name}-data-"
  encryption_enabled = true # Fixed: SSE-S3 default encryption
}

module "storage_reports" {
  source = "./modules/storage"

  bucket_prefix      = "${var.name}-reports-"
  encryption_enabled = true
}
