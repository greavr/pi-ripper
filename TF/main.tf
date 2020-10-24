// Google Cloud provider & Beta
provider "google" {
  project = var.gcp-project-name
  region = var.region
}

provider "google-beta" {
  project = var.gcp-project-name
}

# Enable GCS Storage
resource "google_project_service" "enable-storage" {
  project = var.gcp-project-name
  service = "storage-component.googleapis.com"
  disable_on_destroy = false
}

# Create Bucket for code & Upload it
resource "google_storage_bucket" "bucket" {
  name =  format("%s-cf-sms", var.gcp-project-name)
}

## Create Zip file
data "archive_file" "session_code" {
  type        = "zip"
  output_path = "../artifacts/code.zip"
  source_dir = "../CF"
}

## Upload file to GCS Bucket
resource "google_storage_bucket_object" "code" {
  name   = "code.zip"
  bucket = google_storage_bucket.bucket.name
  source = "../artifacts/code.zip"
}

## CF Code
resource "google_project_service" "enable-cloud-functions" {
  project = var.gcp-project-name
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_cloudfunctions_function" "autoscaler-function" {
  description = "SMS_Notifier"
  runtime     = "python37"
  region  = var.region
  name = "SMS_Notifier"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.code.name
  trigger_http          = true
  timeout               = 60
  entry_point           = "send_sms"

   environment_variables = {
    "number" = var.txt_num
  }

}

# Assign permissions to allow anon invocation
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.gcp-project-name
  cloud_function = google_cloudfunctions_function.autoscaler-function.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# Enable Secrets
resource "google_project_service" "enable-secret" {
  project = var.gcp-project-name
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}


# Create Secrets
resource "google_secret_manager_secret" "sender" {
  provider = google-beta
  secret_id   = "sender_num"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.enable-secret]
}

resource "google_secret_manager_secret" "auth" {
  provider = google-beta
  secret_id   = "auth"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.enable-secret]
}

resource "google_secret_manager_secret" "sid" {
  provider = google-beta
  secret_id   = "sid"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.enable-secret]
}

# Add the secret data for secrets
resource "google_secret_manager_secret_version" "sender-value" {
  secret = google_secret_manager_secret.sender.id
  secret_data = var.sender
}

resource "google_secret_manager_secret_version" "auth-value" {
  secret = google_secret_manager_secret.auth.id
  secret_data = var.auth
}

resource "google_secret_manager_secret_version" "sid-value" {
  secret = google_secret_manager_secret.sid.id
  secret_data = var.sid
}