
resource "google_storage_bucket_object" "archive" {
  name   = var.object-name
  bucket = var.bucket-name
  source = var.function-path
}

resource "google_cloudfunctions_function" "function" {
  name        = var.function-name
  description = var.function-description
  runtime     = var.runtime

  available_memory_mb   = 512
  source_archive_bucket = var.bucket-name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true
  entry_point           = var.entry-point
}

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
