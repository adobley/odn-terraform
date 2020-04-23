data "template_file" "worker_config" {
  template = "${file("${path.module}/template/worker.yml")}"
  vars = {
    DNS_SERVICE_IP = "10.3.0.10"
    ETCD_IP = "${digitalocean_droplet.k8s_etcd.ipv4_address_private}"
    MASTER_HOST = "${digitalocean_droplet.k8s_master.ipv4_address_private}"
    HYPERKUBE_VERSION = "${var.hyperkube_version}"
  }
}

resource "digitalocean_droplet" "k8s_worker" {
  image = "coreos-stable"
  count = "${var.num_workers}"
  name = "${var.prefix}${format("-k8s-worker-%02d", count.index + 1)}"
  region = "${var.do_region}"
  size = "${var.size_worker}"
  user_data = "${data.template_file.worker_config.rendered}"
  private_networking = true
  ssh_keys = [ "${var.ssh_fingerprint}" ]

  connection {
    user = "core"
    type = "ssh"
    private_key = "${file("${var.private_key}")}"
    timeout = "2m"
  }

  # Generate client certificate
  provisioner "local-exec" {
    command = <<EOF
      ${path.module}/gen_client_cert.sh k8s-worker
EOF
  }

  # Add certificate files to server
  provisioner "file" {
    source = "${path.module}/out/ca.pem"
    destination = "/home/core/ca.pem"
  }

  provisioner "file" {
    source = "${path.module}/out/client-k8s-worker.pem"
    destination = "/home/core/worker.pem"
  }

  provisioner "file" {
    source = "${path.module}/out/client-k8s-worker-key.pem"
    destination = "/home/core/worker-key.pem"
  }

  # TODO: Permissions (chown/chmod) key files
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/kubernetes/ssl",
      "sudo cp /home/core/{ca,worker,worker-key}.pem /etc/kubernetes/ssl/.",
      "sudo mkdir -p /etc/ssl/etcd/",
      "sudo mv /home/core/{ca,worker,worker-key}.pem /etc/ssl/etcd/."
    ]
  }

  # Start kubelet
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl start flanneld",
      "sudo systemctl enable flanneld",
      "sudo systemctl start kubelet",
      "sudo systemctl enable kubelet"
    ]
  }
}