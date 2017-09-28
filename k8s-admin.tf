resource "null_resource" "gen_admin" {
  depends_on = ["digitalocean_droplet.k8s_worker"]
  provisioner "local-exec" {
    command = <<EOF
      ${path.module}/gen_admin.sh k8s-master
EOF
  }
}