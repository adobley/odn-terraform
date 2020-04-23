resource "digitalocean_droplet" "k8s_etcd" {
  image = "coreos-stable"
  name = "${var.prefix}-k8s-etcd"
  region = var.do_region
  size = var.size_etcd
  user_data = file("${path.module}/config/etcd.yaml")
  private_networking = true
  ssh_keys = [ "${var.ssh_fingerprint}" ]

  connection {
    user = "core"
    type = "ssh"
    host = self.ipv4_address
    private_key = file(var.private_key)
    timeout = "2m"
  }

  # Generate Certificate Authority
  provisioner "local-exec" {
    command = <<EOF
      ${path.module}/gen_ca.sh
EOF
  }

  # Generate server certificate
  provisioner "local-exec" {
    command = <<EOF
      ${path.module}/gen_server_cert.sh k8s-etcd ${digitalocean_droplet.k8s_etcd.ipv4_address_private}
EOF
  }

  # Add certificate files to server
  provisioner "file" {
    source = "${path.module}/out/ca.pem"
    destination = "/home/core/ca.pem"
  }

  provisioner "file" {
    source = "${path.module}/out/k8s-etcd.pem"
    destination = "/home/core/k8s.pem"
  }

  provisioner "file" {
    source = "${path.module}/out/k8s-etcd-key.pem"
    destination = "/home/core/k8s-key.pem"
  }

  # Move certificate files to k8s ssl dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/kubernetes/ssl",
      "sudo mv /home/core/{ca,k8s,k8s-key}.pem /etc/kubernetes/ssl/."
    ]
  }

  # Start etcd2
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl start etcd2",
      "sudo systemctl enable etcd2",
    ]
  }
}
