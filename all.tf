variable "region" { default = "sfo3" }
variable "do_token" {}
variable "grafana_cloud_username" {}
variable "grafana_cloud_password" {}

terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_project" "dhanush-arch" {
  name        = "dhanush.arch"
  description = "demo website"
  purpose     = "My personal website."
  environment = "Production"
  resources   = flatten([
    digitalocean_droplet.bastion.urn,
    digitalocean_droplet.web.urn,
    digitalocean_loadbalancer.default.urn,
    # digitalocean_domain.default.urn,
  ])
}

resource "digitalocean_ssh_key" "default" {
  name       = "sample-1"
  # public_key = file("~/.ssh/id_rsa.pub")
  public_key = file("uploader.pub")
}

resource "digitalocean_vpc" "default" {
  name     = "dhanush.arch"
  region   = var.region
  ip_range = "10.123.0.0/24"
}

resource "digitalocean_droplet" "bastion" {
  image          = "ubuntu-20-04-x64"
  name           = "bastion"
  region         = var.region
  size           = "s-1vcpu-1gb"
  droplet_agent  = true
  tags           = []
  vpc_uuid       = resource.digitalocean_vpc.default.id
  ssh_keys       = [digitalocean_ssh_key.default.fingerprint]

  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -qy prometheus nginx",

      "useradd -m uploader",
      "mkdir ~uploader/.ssh",
      "echo '${file("uploader.pub")}' > ~uploader/.ssh/authorized_keys",
      "chown -R uploader ~uploader/.ssh/authorized_keys",
      "chmod 0600 ~uploader/.ssh/authorized_keys",

      "mkdir -p /files/uploads",
      "echo bastion > /files/hostname",
      "chown uploader /files/uploads",
    ]
  }

  provisioner "file" {
    destination = "/etc/prometheus/prometheus.yml"
    content     = templatefile("prometheus.yml.template", {
        instances = resource.digitalocean_droplet.web,
        grafana_cloud_username = var.grafana_cloud_username,
        grafana_cloud_password = var.grafana_cloud_password,
      })
  }

  provisioner "file" {
    destination = "/etc/default/prometheus"
    content     = "ARGS=\"--web.listen-address=127.0.0.1:9090\""
  }

  provisioner "file" {
    destination = "/etc/nginx/sites-enabled/default"
    content     = "server { listen  ${self.ipv4_address_private}:80; location / { root /files; } }"
  }

  provisioner "file" {
    destination = "/etc/ssh/sshd_config"
    content     = file("sshd_config")
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl restart prometheus",
      "systemctl restart nginx",
      "systemctl restart sshd",
    ]
  }
}

resource "digitalocean_droplet" "web" {
  image          = "ubuntu-20-04-x64"
  name           = "web"
  region         = var.region
  size           = "s-1vcpu-1gb"
  droplet_agent  = false
  tags           = ["unikernel"]
  user_data      = file("boot.sh")
  vpc_uuid       = resource.digitalocean_vpc.default.id
  ssh_keys       = [digitalocean_ssh_key.default.fingerprint]

  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -qy python3-pip opensmtpd",
      "pip3 install requests jinja2",
    ]
  }

  provisioner "file" {
    destination = "/usr/local/bin/boot.py"
    content     = file("boot.py")
  }
}

resource "digitalocean_loadbalancer" "default" {
  name                     = "sfo3-load-balancer-01"
  region                   = var.region
  size                     = "lb-small"
  enable_backend_keepalive = true

  vpc_uuid    = resource.digitalocean_vpc.default.id
  droplet_ids = [digitalocean_droplet.web.id]

  forwarding_rule {
    entry_port       = 80
    entry_protocol   = "http"
    target_port      = 80
    target_protocol  = "http"
  }
  

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/"
  }
}

# resource "digitalocean_certificate" "default" {
#   name    = "dhanusharch.me"
#   type    = "lets_encrypt"
#   domains = ["dhanusharch.me"]

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "digitalocean_domain" "default" {
#   name = "dhanusharch.me"
# }

# resource "digitalocean_record" "mx0" {
#   domain   = digitalocean_domain.default.name
#   type     = "MX"
#   name     = "@"
#   priority = 5
#   value   = "gmr-smtp-in.l.google.com."
# }

# resource "digitalocean_record" "mx1" {
#   domain   = digitalocean_domain.default.name
#   type     = "MX"
#   name     = "@"
#   priority = 10
#   value   = "alt1.gmr-smtp-in.l.google.com."
# }

# resource "digitalocean_record" "mx2" {
#   domain   = digitalocean_domain.default.name
#   type     = "MX"
#   name     = "@"
#   priority = 20
#   value   = "alt2.gmr-smtp-in.l.google.com."
# }

# resource "digitalocean_record" "mx3" {
#   domain   = digitalocean_domain.default.name
#   type     = "MX"
#   name     = "@"
#   priority = 30
#   value   = "alt3.gmr-smtp-in.l.google.com."
# }

# resource "digitalocean_record" "mx4" {
#   domain   = digitalocean_domain.default.name
#   type     = "MX"
#   name     = "@"
#   priority = 40
#   value   = "alt4.gmr-smtp-in.l.google.com."
# }
