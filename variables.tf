variable "rotation_days" {
  type        = number
  description = "Days until secret needs to be recreated. Note: the default of this value is its current maximum value."
  default     = 730
}

variable "rotation_window_days" {
  type        = number
  description = "Days to begin recreating secret within if Terraform is run during this time."
  default     = 365
}
