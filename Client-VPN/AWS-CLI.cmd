# متغیرها
REGION=eu-west-3                        # مثال: Paris
VPC_ID=vpc-0123456789abcdef0
SUBNET_ID=subnet-0123456789abcdef0      # Subnet با مسیر به IGW/NAT
SERVER_CERT_ARN=arn:aws:acm:...:certificate/...
CLIENT_ROOT_CA_ARN=arn:aws:acm:...:certificate/...
CORP_EIP=198.51.100.10                  # EIP ثابت NAT
OU_ID=ou-abcd-efghijk

# 1) ساخت Client VPN Endpoint (Full-Tunnel: فلگ split-tunnel را نمی‌دهیم)
aws ec2 create-client-vpn-endpoint \
  --region $REGION \
  --server-certificate-arn "$SERVER_CERT_ARN" \
  --client-cidr-block "172.31.0.0/22" \
  --authentication-options Type=certificate-authentication,RootCertificateChainArn="$CLIENT_ROOT_CA_ARN" \
  --connection-log-options Enabled=true,CloudwatchLogGroup="/aws/vpn/client",CloudwatchLogStream="connections" \
  --transport-protocol udp

# خروجی را بردارید:
CVPN_ENDPOINT_ID=cvpn-endpoint-xxxxxxxx

# 2) اتصال Endpoint به Subnet عمومی
aws ec2 associate-client-vpn-target-network \
  --region $REGION \
  --client-vpn-endpoint-id $CVPN_ENDPOINT_ID \
  --subnet-id $SUBNET_ID

# 3) اجازه کلی (Authorization) برای همه مقصدها
aws ec2 authorize-client-vpn-ingress \
  --region $REGION \
  --client-vpn-endpoint-id $CVPN_ENDPOINT_ID \
  --target-network-cidr "0.0.0.0/0" \
  --authorize-all-groups

# 4) Route اینترنت برای Full-Tunnel
aws ec2 create-client-vpn-route \
  --region $REGION \
  --client-vpn-endpoint-id $CVPN_ENDPOINT_ID \
  --destination-cidr-block "0.0.0.0/0" \
  --target-vpc-subnet-id $SUBNET_ID

# 5) دریافت فایل کانفیگ کلاینت (.ovpn)
aws ec2 export-client-vpn-client-configuration \
  --region $REGION \
  --client-vpn-endpoint-id $CVPN_ENDPOINT_ID \
  --output text > client-config.ovpn

# (کلاینت) فایل‌های client.crt / client.key را طبق راهنما به کلاینت بدهید.

# 6) ساخت SCP که فقط از EIP سازمانی اجازه می‌دهد
read -r -d '' SCP_JSON <<'JSON'
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"DenyFromUnapprovedIPs",
      "Effect":"Deny",
      "Action":"*",
      "Resource":"*",
      "Condition":{
        "NotIpAddress":{"aws:SourceIp":["__CORP_EIP__/32"]}
      }
    }
  ]
}
JSON

echo "$SCP_JSON" | sed "s#__CORP_EIP__#$CORP_EIP#g" > scp-allow-only-corp-ip.json

POLICY_ID=$(aws organizations create-policy \
  --type SERVICE_CONTROL_POLICY \
  --name "AllowOnlyFromCorporateEIP" \
  --description "Blocks all access unless requests come from corporate EIP" \
  --content file://scp-allow-only-corp-ip.json \
  --query 'Policy.PolicySummary.Id' --output text)

# 7) اتصال SCP به OU
aws organizations attach-policy \
  --policy-id "$POLICY_ID" \
  --target-id "$OU_ID"
