resource "null_resource" "deploy_microbot" {
  depends_on = ["null_resource.setup_kubectl"]
  provisioner "local-exec" {
    command = <<EOF
      sed -e "s/\$EXT_IP1/${digitalocean_droplet.k8s_worker.0.ipv4_address}/" < ${path.module}/config/microbot.yml > ./out/microbot.rendered.yml
      until kubectl get pods 2>/dev/null; do printf '.'; sleep 5; done
      kubectl create -f ./out/microbot.rendered.yml
EOF
  }
}