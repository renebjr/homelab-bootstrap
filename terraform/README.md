## Terraform cheatsheet

### Before running (once per shell)

```bash
export DIGITALOCEAN_TOKEN="$(cat ~/.secrets/digitalocean_token)"
export PC_USER_NAME="yourname"
```

Also needed: `~/.secrets/pc_user_pw` (password only, no other text).

### Everyday commands

| Command                              | What it does                                         |
| ------------------------------------ | ---------------------------------------------------- |
| `terraform fmt`                      | Formats `.tf` files                                  |
| `terraform init`                     | Downloads providers (first run, or after adding one) |
| `terraform validate`                 | Checks syntax and references, offline                |
| `terraform plan`                     | Previews changes, touches nothing                    |
| `terraform apply`                    | Creates or changes resources (asks for `yes`)        |
| `terraform output -raw ipv4_address` | Prints the droplet's IP                              |
| `terraform output -raw ssh_command`  | Prints the login command                             |

### Changing and removing

| Command                                              | What it does                                                         |
| ---------------------------------------------------- | -------------------------------------------------------------------- |
| `terraform apply -replace=digitalocean_droplet.this` | Rebuilds only the droplet (needed to apply cloud-init edits)         |
| `terraform plan -destroy`                            | Previews a teardown                                                  |
| `terraform destroy`                                  | Deletes everything managed here, including backups and the key files |

### Inspecting

| Command                | What it does                          |
| ---------------------- | ------------------------------------- |
| `terraform state list` | Lists resources Terraform is tracking |
| `terraform show`       | Shows the current state               |
| `terraform console`    | Interactive expression prompt         |

### Commit / don't commit

- Commit: `*.tf`, `cloud-init.yaml.tftpl`, `.terraform.lock.hcl`, `.gitignore`
- Never commit: `terraform.tfstate*` (contains the private key and password hash) and `.terraform/`
- Back up the state file somewhere private. Without it, Terraform loses track of the droplet.

### Gotchas

- `user_data` is in `ignore_changes`, so editing the cloud-init template does nothing until you use `-replace` above.
- The droplet size isn't available in every region. If apply fails with "Size is not available in this region", change the region.
- Root SSH is disabled. Log in as your user, then `sudo -i`.
