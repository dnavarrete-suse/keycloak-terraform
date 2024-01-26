provider "digitalocean" {
  token = var.do_token
}

locals {
  message = {
    informational = "You shall now wait around 5 minutes for the harbor installation to complete, you will be able to access your instance here keycloak-${var.instance_suffix}.${var.digitalocean_domain}"
  }
}

data "digitalocean_account" "do-account" {
}

data "template_file" "keycloak" {
  template = file("files/keycloak-configuration.sh")
  vars = {
    docker_version = var.docker_version
    dns_record = "keycloak-${var.instance_suffix}.${var.digitalocean_domain}"
    keycloak_password = var.keycloak_password
    email = var.email
  }
}

resource "digitalocean_droplet" "keycloak" {
  count              = 1
  image              = var.image
  name               = "keycloak-${var.instance_suffix}"
  private_networking = true
  region             = var.region
  size               = var.size
  user_data          = data.template_file.keycloak.rendered 
  ssh_keys           = var.ssh_keys
  tags               = [join("", ["user:", replace(split("@", data.digitalocean_account.do-account.email)[0], ".", "-")])]
}

resource "digitalocean_record" "dns" {
  domain = var.digitalocean_domain
  type   = "A"
  ttl    = 30
  name   = "keycloak-${var.instance_suffix}"
  value  = digitalocean_droplet.keycloak[0].ipv4_address
}

resource "local_file" "ssh_config" {
  content = templatefile("${path.module}/files/ssh_config.tmpl", {
    instance_suffix  = var.instance_suffix,
    keycloak           = digitalocean_droplet.keycloak[0].ipv4_address,
  })
  filename = "${path.module}/ssh_config"
}

output "keycloak" {
    value = data.template_file.keycloak.rendered
}

output "Informational" {
    value = local.message.informational
}
