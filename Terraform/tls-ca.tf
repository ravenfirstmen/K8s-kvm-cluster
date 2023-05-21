
# resource "tls_private_key" "k8s_ca_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# resource "tls_self_signed_cert" "k8s_ca_cert" {
#   private_key_pem   = tls_private_key.k8s_ca_key.private_key_pem
#   is_ca_certificate = true

#   subject {
#     common_name  = "K8s CA" // /CN=${MASTER_IP}
#     organization = "Virtual"
#   }

#   validity_period_hours = 8760

#   allowed_uses = [
#     "cert_signing",
#     "key_encipherment",
#     "digital_signature"
#   ]
# }

# resource "local_file" "k8s_ca_private_key" {
#   content         = tls_private_key.k8s_ca_key.private_key_pem
#   filename        = "./certs/k8s-ca-key.pem"
#   file_permission = "0600"
# }

# resource "local_file" "k8s_ca_public_key" {
#   content         = tls_self_signed_cert.k8s_ca_cert.cert_pem
#   filename        = "./certs/k8s-ca.pem"
#   file_permission = "0600"
# }

data "tls_certificate" "k8s_ca_cert" {
  content = file("./certs/public-ca-crt.pem")
}

data "tls_public_key" "k8s_ca_key" {
  private_key_pem = file("./certs/public-ca-key.pem")
}
