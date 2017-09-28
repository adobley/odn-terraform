variable "do_token" {}
variable "do_region" {
    default = "nyc3"
}
variable "public_key" {}
variable "private_key" {}
variable "ssh_fingerprint" {}

variable num_workers {
    default = 3
}
variable "hyperkube_version" {
    default = "v1.7.3_coreos.0"
}

variable "prefix" {
    default = "odn"
}

variable "size_etcd" {
    default = "512mb"
}

variable "size_master" {
    default = "1gb"
}

variable "size_worker" {
    default = "512mb"
}
