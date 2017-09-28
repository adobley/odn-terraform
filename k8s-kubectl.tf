resource "null_resource" "setup_kubectl" {
  depends_on = ["null_resource.gen_admin"]
  provisioner "local-exec" {
    command = <<EOF
      echo export MASTER_HOST=${digitalocean_droplet.k8s_master.ipv4_address} > $PWD/out/setup_kubectl.sh
      echo export CA_CERT=$PWD/out/ca.pem >> $PWD/out/setup_kubectl.sh
      echo export ADMIN_KEY=$PWD/out/admin-key.pem >> $PWD/out/setup_kubectl.sh
      echo export ADMIN_CERT=$PWD/out/admin.pem >> $PWD/out/setup_kubectl.sh
      . $PWD/out/setup_kubectl.sh
      kubectl config set-cluster default-cluster \
        --server=https://$MASTER_HOST --certificate-authority=$CA_CERT
        kubectl config set-credentials default-admin \
        --certificate-authority=$CA_CERT --client-key=$ADMIN_KEY --client-certificate=$ADMIN_CERT
      kubectl config set-context default-system --cluster=default-cluster --user=default-admin
      kubectl config use-context default-system
EOF
  }
}