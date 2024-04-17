variable "source_location" {
  description = "The Azure Region in which the source resources will be deployed."
  type        = string
  default     = "francecentral"
}

variable "target_location" {
  description = "The Azure Region in which the target resources will be deployed."
  type        = string
  default     = "francecentral"
}
