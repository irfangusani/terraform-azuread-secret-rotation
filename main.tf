terraform {
  required_version = ">= 1.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

locals {
  # Calculate when the rotation window should open
  # Example: 730 day expiry - 365 day window = rotation starts at day 365
  refresh_after_days = var.rotation_days - var.rotation_window_days
}

resource "time_rotating" "refresh_window" {
  rotation_days = local.refresh_after_days
}

resource "time_rotating" "app_password_expiration" {
  rotation_days = var.rotation_days
}

resource "azuread_application" "app" {
  display_name = "a cool application"
}

resource "azuread_application_password" "app_password" {
  application_id = azuread_application.app.id
  start_date     = time_rotating.app_password_expiration.rfc3339
  end_date       = time_rotating.app_password_expiration.rotation_rfc3339

  rotate_when_changed = {
    time_rotation = time_rotating.refresh_window.rfc3339
  }
}
