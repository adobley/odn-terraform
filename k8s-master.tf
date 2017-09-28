data "template_file" "master_config" {
  template = "${file("${path.module}/template/master.yml")}"
  vars {
    DNS_SERVICE_IP = "10.3.0.10"
    ETCD_IP = "${digitalocean_droplet.k8s_etcd.ipv4_address_private}"
    POD_NETWORK = "10.2.0.0/16"
    SERVICE_IP_RANGE = "10.3.0.0/24"
    HYPERKUBE_VERSION = "${var.hyperkube_version}"
  }
}

resource "digitalocean_droplet" "k8s_master" {
  image = "coreos-stable"
  name = "${var.prefix}-k8s-master"
  region = "${var.do_region}"
  size = "${var.size_master}"
  user_data = "${data.template_file.master_config.rendered}"
  private_networking = true
  ssh_keys = [ "${var.ssh_fingerprint}" ]

  connection {
    user = "core"
    type = "ssh"
    private_key = "${file("${var.private_key}")}"
    timeout = "2m"
  }

  # Generate server certificate
  provisioner "local-exec" {
    command = <<EOF
      ${path.module}/gen_server_cert.sh k8s-master "${digitalocean_droplet.k8s_master.ipv4_address},${digitalocean_droplet.k8s_master.ipv4_address_private},10.3.0.1,kubernetes.default,kubernetes"
EOF
  }

  # Add certificate files to server
  provisioner "file" {
    source = "${path.module}/out/ca.pem"
    destination = "/home/core/ca.pem"
  }

  provisioner "file" {
    source = "${path.module}/out/k8s-master.pem"
    destination = "/home/core/apiserver.pem"
  }

  provisioner "file" {
    source = "${path.module}/out/k8s-master-key.pem"
    destination = "/home/core/apiserver-key.pem"
  }

  # Generate k8s_master client certificate
  provisioner "local-exec" {
    command = <<EOF
      ${path.module}/gen_client_cert.sh k8s-master
EOF
  }

  # Add client cert to server
  provisioner "file" {
    source = "${path.module}/out/client-k8s-master.pem"
    destination = "/home/core/client.pem"
  }

  provisioner "file" {
    source = "${path.module}/out/client-k8s-master-key.pem"
    destination = "/home/core/client-key.pem"
  }

  provisioner "file" {
    source = "${var.private_key}"
    destination = "/home/core/.ssh/id_rsa"
  }

  # TODO: Permissions (chown/chmod) key files
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/kubernetes/ssl",
      "sudo cp /home/core/{ca,apiserver,apiserver-key,client,client-key}.pem /etc/kubernetes/ssl/.",
      "rm /home/core/{apiserver,apiserver-key}.pem",
      "sudo mkdir -p /etc/ssl/etcd",
      "sudo mv /home/core/{ca,client,client-key}.pem /etc/ssl/etcd/.",
    ]
  }

  # Start kubelet
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl daemon-reload",
      "curl --cacert /etc/kubernetes/ssl/ca.pem --cert /etc/kubernetes/ssl/client.pem --key /etc/kubernetes/ssl/client-key.pem -X PUT -d 'value={\"Network\":\"10.2.0.0/16\",\"Backend\":{\"Type\":\"vxlan\"}}' https://${digitalocean_droplet.k8s_etcd.ipv4_address_private}:2379/v2/keys/coreos.com/network/config",
      "sudo systemctl start flanneld",
      "sudo systemctl enable flanneld",
      "sudo systemctl start kubelet",
      "sudo systemctl enable kubelet"
    ]
  }
}