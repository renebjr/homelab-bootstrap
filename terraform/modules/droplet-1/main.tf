terraform {
  required_version = ">= 1.5"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

# Reads the API token from the DIGITALOCEAN_TOKEN environment variable.
provider "digitalocean" {}

# ---------------------------------------------------------------------------
# Username (read straight from the PC_USER_ environment variable)
# ---------------------------------------------------------------------------
# Terraform can only read TF_VAR_* variables natively, so the official
# "external" data source is used to read PC_USER_ from the machine environment.
# Requires a POSIX shell (Linux, macOS, WSL).
data "external" "env" {
  program = ["sh", "-c", "printf '{\"pc_user_name\":\"%s\"}' \"$PC_USER_NAME\""]
}

locals {
  pc_user_name = data.external.env.result.pc_user_name
}

# ---------------------------------------------------------------------------
# SSH key (created by Terraform)
# ---------------------------------------------------------------------------
resource "tls_private_key" "droplet" {
  algorithm = "ED25519"
}

# Private key goes to ~/.ssh with 0600 permissions.
resource "local_sensitive_file" "private_key" {
  content              = tls_private_key.droplet.private_key_openssh
  filename             = pathexpand("~/.ssh/${var.droplet_name}_ed25519")
  file_permission      = "0600"
  directory_permission = "0700"
}

# Matching public key next to it.
resource "local_file" "public_key" {
  content              = tls_private_key.droplet.public_key_openssh
  filename             = "${local_sensitive_file.private_key.filename}.pub"
  file_permission      = "0644"
  directory_permission = "0700"
}

# Registered with DigitalOcean so the droplet doesn't get an emailed root password.
resource "digitalocean_ssh_key" "droplet" {
  name       = "${var.droplet_name}-key"
  public_key = trimspace(tls_private_key.droplet.public_key_openssh)
}

# ---------------------------------------------------------------------------
# User password (read from the secret file, hashed before it leaves your machine)
# ---------------------------------------------------------------------------
locals {
  # bcrypt() uses a random salt, so this value changes on every plan.
  # That is why user_data is in ignore_changes below.
  pc_user_pw_hash = sensitive(bcrypt(trimspace(file(pathexpand("~/.secrets/pc_user_pw")))))
}

# ---------------------------------------------------------------------------
# Droplet
# ---------------------------------------------------------------------------
resource "digitalocean_droplet" "this" {
  name     = var.droplet_name
  region   = var.region
  size     = "s-1vcpu-1gb"
  image    = var.image
  ssh_keys = [digitalocean_ssh_key.droplet.fingerprint]

  backups = true
  backup_policy {
    plan    = "weekly"
    weekday = "SUN"
    hour    = 4
  }

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    username       = local.pc_user_name
    password_hash  = local.pc_user_pw_hash
    ssh_public_key = trimspace(tls_private_key.droplet.public_key_openssh)
  })

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", local.pc_user_name)) && local.pc_user_name != "root"
      error_message = "PC_USER_NAME must be set to a valid, non-root Linux username (lowercase letters, digits, _ or -)."
    }

    # user_data forces droplet replacement when it changes, and the bcrypt
    # salt changes every run. Ignore it so only an explicit
    # `terraform apply -replace=digitalocean_droplet.this` rebuilds the droplet.
    ignore_changes = [user_data]
  }
}