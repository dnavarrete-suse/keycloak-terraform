# Terraform to install Keycloak on DigitalOcean

Terraform will just create an Ubuntu droplet and a DNS record. 

A script will run to install everything needed. Including certificates for Keycloak using certbot. 

After around 5min. keycloak will be available at keycloak-{suffix-from-terraform-tf-vars}.{digital-ocean-domain}.

## Installation

Fill the variables under terraform.tfvars. If the email is invalid, certbot will fail.

Then just use it as a normal Terraform project
```bash
  terraform init
  terraform apply -auto-approve
```
## Troubleshooting

If keycloak does not come up, ssh into the host created by terraform and run a "docker ps" and "docker logs" to see why it failed. 
