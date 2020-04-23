terraform destroy -var "do_token=${DO_PAT}" -var "public_key=$HOME/.ssh/id_rsa.pub" -var "private_key=$HOME/.ssh/id_rsa" -var "ssh_fingerprint=$SSH_FINGERPRINT"
