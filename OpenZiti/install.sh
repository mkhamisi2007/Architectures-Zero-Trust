#--install on Ec2 ------------
UBUNTU_LTS=focal;

curl -sSLf https://get.openziti.io/tun/package-repos.gpg \
| sudo gpg --dearmor --output /usr/share/keyrings/openziti.gpg;
sudo chmod +r /usr/share/keyrings/openziti.gpg;

sudo tee /etc/apt/sources.list.d/ziti-edge-tunnel-testing.list >/dev/null <<EOF;
deb [signed-by=/usr/share/keyrings/openziti.gpg] https://packages.openziti.org/zitipax-openziti-deb-test ${UBUNTU_LTS} main
EOF

sudo apt update;
sudo apt install ziti-edge-tunnel;
ziti-edge-tunnel version;
