terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 6.8.0"
    }
  }

}

provider "google" {
  project = var.project_id
  region  = var.region
}
# Enable Cloud Resource Manager API
# resource "google_project_service" "cloudresourcemanager" {
#   project = var.project_id
#   service = "cloudresourcemanager.googleapis.com"
# }

# Create a public subnet in the default VPC
resource "google_compute_subnetwork" "public_subnet" {
  name          = "gke-public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = "default"
}


resource "google_container_cluster" "demo_cluster" {
  name               = var.cluster_name
  location           = var.region
  initial_node_count = 1

  # Network and Subnet
  network    = "default"
  subnetwork = google_compute_subnetwork.public_subnet.name

  deletion_protection = false

  # IAM roles and permissions for GKE
  remove_default_node_pool = true
  node_locations           = ["us-central1-a"]
}

# Create a node pool for the GKE cluster
resource "google_container_node_pool" "demo_node_pool" {
  name       = "primary-node-pool"
  location   = var.region
  cluster    = google_container_cluster.demo_cluster.name
  node_count = 1

  node_config {
    machine_type = "e2-medium"

    # Use preemptible nodes to reduce costs
    preemptible = true

    

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
  }
  
}
# Assign GKE Admin IAM Role
resource "google_project_iam_member" "gke_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${var.service_account_email}"
}

output "cluster_name" {
  value = google_container_cluster.demo_cluster.name
}

output "cluster_endpoint" {
  value = google_container_cluster.demo_cluster.endpoint
}
