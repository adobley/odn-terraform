# ODN-Terraform

The primary purpose of this is to be the terraform repo for my own servers. I host with DigitalOcean so the only provider is with them. When I get around to adding DNS I might move it over to DigitalOcean to keep it all in one place.

I have tried to make things generic where it seems reasonable to make it friendly to others who may want to use it or copy parts for themselves.

It will probably always be a work in progress.

## Prerequeisites

* [Install go](https://golang.org/doc/install), I think 1.4+ is okay, but as of this writing I'm on 1.9.

* [Install cfssl](https://github.com/cloudflare/cfssl)

```bash
$ go get -u github.com/cloudflare/cfssl/cmd/...
$ cfssl version
Version: 1.2.0
Revision: dev
Runtime: go1.9
```

* [Upload flatcar image to DigitalOcean](https://docs.flatcar-linux.org/os/booting-on-digitalocean/) I used the stable channel and named it `var.image_id`
NOTE: DigitalOcean did not assign a slug for my image. I had to use their API to [list my private images](https://developers.digitalocean.com/documentation/v2/#list-a-user-s-images) and get the ID.

## Usage

I exported my ssh fingerprint to SSH_FINGERPRINT for ease of use.

How I call the script:

```bash
terraform plan -var "do_token=${DO_PAT}" -var "public_key=$HOME/.ssh/id_rsa.pub" -var "private_key=$HOME/.ssh/id_rsa" -var "ssh_fingerprint=$SSH_FINGERPRINT" -out=plan
```

I check what is being destroyed, what is being added, based on my tfstate. If the plan looks good then:

```bash
terraform apply plan
```

A lot of the variables are defined in provider.tf with defaults. I'll try to keep this list up to date. If they have a default they are listed on the child bullet.

* do_token - Digital Ocean API Token
* do_region - Digital Ocean deploy region
  * nyc3
* public_key - Your public key, I think I put this in and am not using it yet?
* private_key - Your private key for connecting to the server. Should be added to your DigitalOcean page.
* ssh_fingerprint - Your ssh_fingerprint. You can find this yourself or grab it from DigitalOcean when you add your SSH key.
* image_id - The ID or slug for the Digital Ocean image you want to use. This is designed to work with `flatcar`.
* num_workers - Number of k8s worker nodes
  * 3
* hyperkube_version - Version of hyperkube, a collection of k8s executables, I'd like to find a way to pin this to latest stable
  * v1.7.3_coreos.0
* prefix - The prefix for all the servers. odn is for my personal servers on DO
  * odn
* size_etcd - Size of the dedicated TLS+Auth etcd2 instance for k8s, 512 might be a bit small but my personal servers don't need much and I'd rather start small to save money
  * 512mb
* size_master - Cluster master running all the things, not built out yet so I don't know yet what this will look like
  * 512mb
* size_worker - Size for worker nodes
  * 512mb

## ToDo some day

I'd love to have my tfstate backed up somewhere secure and redundant. Maybe access it via a web service or stick it in a vault.

## Thanks

Big thanks to [kube-digital-terraform](https://github.com/kubernetes-digitalocean-terraform/kubernetes-digitalocean-terraform) for the inspiration behind the cfssl code.
