sudo -i
apt update --assume-yes
apt upgrade --assume-yes
reboot
apt install --assume-yes curl unzip
curl  https://raw.githubusercontent.com/ferrumgate/secure.install/master/install.sh | sh
ferrumgate --start





