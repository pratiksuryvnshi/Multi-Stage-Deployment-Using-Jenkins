terraform {
  backend "gcs" {
    bucket  = "yavan-bucket"
    prefix  = "terraform/state"
  }
}
