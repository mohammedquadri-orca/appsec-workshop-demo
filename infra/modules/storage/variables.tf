variable "bucket_prefix" {
  description = "Prefix for the generated bucket name."
  type        = string
}

variable "encryption_enabled" {
  description = "Whether to configure default server-side encryption (SSE-S3)."
  type        = bool
  default     = true
}
