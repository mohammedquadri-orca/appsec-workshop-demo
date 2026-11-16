output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "image_uri" {
  value = local.image_uri
}

output "instance_id" {
  value = aws_instance.app.id
}

output "instance_private_ip" {
  value = aws_instance.app.private_ip
}

output "data_bucket" {
  value = module.storage.bucket_name
}

output "reports_bucket" {
  value = module.storage_reports.bucket_name
}
