remote_state {
  backend = "gcs"
  config = {
    bucket = "austin-test-harness-bucket"  # Replace with your bucket name
    prefix = "terraform"       # Optional: path inside the bucket to store state
    project = "kubernetes-austin"
    location = "US"
  }
}
