resource "null_resource" "gen_admin" {
  provisioner "local-exec" {
    command = <<EOF
      ${path.module}/gen_admin.sh k8s-master
EOF
  }
}