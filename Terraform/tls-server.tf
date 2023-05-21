locals {
  master_ip         = "127.0.0.1"
  master_cluster_ip = "127.0.0.1"
}

resource "tls_private_key" "k8s_controller_server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "k8s_controller_server_cert" {
  private_key_pem = tls_private_key.k8s_controller_server_key.private_key_pem

  subject {
    common_name         = local.controller_node.fqdn
    country             = "PT"
    province            = "Braga"
    locality            = "Famalicao"
    organization        = "Casa"
    organizational_unit = "Escritorio"
  }

  ip_addresses = [
    local.master_ip,
    local.master_cluster_ip,
    local.controller_node.ip,
  ]

  dns_names = [
    local.controller_node.name,
    local.controller_node.fqdn,
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ]
}

resource "tls_locally_signed_cert" "k8s_controller_server_signed_cert" {
  cert_request_pem = tls_cert_request.k8s_controller_server_cert.cert_request_pem

  # ca_private_key_pem = tls_private_key.k8s_ca_key.private_key_pem
  # ca_cert_pem        = tls_self_signed_cert.k8s_ca_cert.cert_pem
  ca_private_key_pem = data.tls_public_key.k8s_ca_key.private_key_pem
  ca_cert_pem        = data.tls_certificate.k8s_ca_cert.certificates[0].cert_pem

  allowed_uses = [
    "data_encipherment",
    "key_encipherment",
    "client_auth",
    "server_auth",
  ]

  validity_period_hours = 8760
}

resource "local_file" "k8s_controller_server_key" {
  content         = tls_private_key.k8s_controller_server_key.private_key_pem
  filename        = "./certs/k8s-controller-key.pem"
  file_permission = "0600"
}

resource "local_file" "k8s_controller_server_signed_cert" {
  content         = tls_locally_signed_cert.k8s_controller_server_signed_cert.cert_pem
  filename        = "./certs/k8s-controller.pem"
  file_permission = "0600"
}
