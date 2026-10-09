output "ipv4_address" {
  description = "Public IPv4 address of the droplet."
  value       = digitalocean_droplet.this.ipv4_address
}

output "ssh_command" {
  description = "Command to log in as your user."
  value       = "ssh -i ${local_sensitive_file.private_key.filename} ${local.pc_user_name}@${digitalocean_droplet.this.ipv4_address}"
}