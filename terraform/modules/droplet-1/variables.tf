variable "droplet_name" {
  description = "Name of the droplet and initial hostname."
  type        = string
  default     = "west-gate-1"
}

variable "region" {
  description = "DigitalOcean region where the droplet will be created."
  type        = string
  default     = "ams3"
}

variable "image" {
  description = "Droplet image of the chosen OS."
  type        = string
  default     = "ubuntu-24-04-x64"
}