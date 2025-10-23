terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

########################
# Inputs you must provide
########################
variable "region"                 { type = string }
variable "vpc_id"                 { type = string }
variable "public_subnet_id"       { type = string } # ساب‌نتی که Route به IGW/NAT دارد
variable "server_certificate_arn" { type = string } # ACM arn
variable "client_root_cert_arn"   { type = string } # ACM arn (root CA for client certs)
variable "allowed_egress_eip"     { type = string } # همانی که NAT Gateway استفاده می‌کند (مثلا "198.51.100.10")
variable "ou_id"                  { type = string } # مثلا "ou-abcd-efghijk"
# برای ساده‌سازی، Security Group مینیمال می‌سازیم:
resource "aws_security_group" "cvpn_sg" {
  name        = "cvpn-endpoint-sg"
  description = "SG for Client VPN endpoint"
  vpc_id      = var.vpc_id

  # اجازه از کلاینت‌ها به همه مقصدها (خروجی)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ورودی به خود Endpoint مدیریت‌شده نیاز نیست (AWS مدیریت می‌کند)
}

# CloudWatch Logs برای لاگ اتصال‌ها (اختیاری ولی پیشنهادی)
resource "aws_cloudwatch_log_group" "cvpn_lg" {
  name              = "/aws/vpn/client"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "cvpn_ls" {
  name           = "connections"
  log_group_name = aws_cloudwatch_log_group.cvpn_lg.name
}

# Client VPN Endpoint (Full-Tunnel: split_tunnel = false)
resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = "Org Client VPN (Full-Tunnel)"
  server_certificate_arn = var.server_certificate_arn

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_root_cert_arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.cvpn_lg.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.cvpn_ls.name
  }

  split_tunnel   = false # تمام ترافیک از VPN
  dns_servers    = ["8.8.8.8", "1.1.1.1"]
  transport_protocol = "udp"

  # محدوده IP برای کلاینت‌ها (Pool)
  client_cidr_block = "172.31.0.0/22"

  security_group_ids = [aws_security_group.cvpn_sg.id]
  vpc_id             = var.vpc_id
}

# اتصال Endpoint به Subnet عمومی
resource "aws_ec2_client_vpn_network_association" "assoc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.public_subnet_id
}

# اجازه دسترسی کلاینت‌ها به همه مقصدها در VPC و اینترنت (Full-Tunnel)
resource "aws_ec2_client_vpn_authorization_rule" "allow_all" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
  depends_on             = [aws_ec2_client_vpn_network_association.assoc]
}

# Route برای اینترنت (0.0.0.0/0) از طریق Subnet Association
resource "aws_ec2_client_vpn_route" "internet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = var.public_subnet_id
  depends_on             = [aws_ec2_client_vpn_network_association.assoc]
}

##############################
# (اختیاری) SCP برای محدودکردن ورود به Console/API فقط از EIP سازمانی
##############################
# محتوا: Deny برای هر چیزی که از IP عمومی سازمانی نیاید
data "aws_iam_policy_document" "scp_content" {
  statement {
    sid     = "DenyFromUnapprovedIPs"
    effect  = "Deny"
    actions = ["*"]
    resources = ["*"]

    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = [format("%s/32", var.allowed_egress_eip)]
    }
  }
}

resource "aws_organizations_policy" "scp" {
  name        = "AllowOnlyFromCorporateEIP"
  description = "Blocks all access unless requests come from corporate NAT EIP"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.scp_content.json
}

resource "aws_organizations_policy_attachment" "attach_scp" {
  policy_id = aws_organizations_policy.scp.id
  target_id = var.ou_id
}
