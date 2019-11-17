#!/bin/sh

IPV4="";
PRIVATEKEY="";
PUBLICKEY="";
CLOUDFLAREKEY="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";

clear

echo "WireGuard with Warp Autoscript"
echo ""
echo -n "Enter VPS IP: "
read IPV4
echo -n "Enter your generated PRIVATE KEY: "
read PRIVATEKEY
echo -n "Enter your generated PUBLIC KEY: "
read PUBLICKEY

echo ""
echo "This will take 3-5 minutes, wait until the process is finished..."
echo ""

echo "Installing repositories."

# Installing repositories
sudo add-apt-repository ppa:wireguard/wireguard -y > out.log 2> /dev/null
apt-get update -y > out.log 2> /dev/null
apt-get install wireguard-dkms wireguard-tools -y > out.log 2> /dev/null
apt install jq -y > out.log 2> /dev/null

echo "Configuring the wireguard server."

# Server Configuring
echo '[Interface]
PrivateKey = '$PRIVATEKEY'
Address = '$IPV4'/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true' > /etc/wireguard/wg0.conf

echo "Starting the server."
echo ""

#Starting Server
wg-quick up wg0 > out.log 2> /dev/null
sudo systemctl enable wg-quick@wg0 > out.log 2> /dev/null

echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/ipv4_forwarding.conf > out.log 2> /dev/null
sysctl --system > out.log 2> /dev/null

echo "Registering your server into Cloudflare."

curl -d '{"key":"'$PUBLICKEY'", "install_id":"", "warp_enabled":true, "tos":"2019-11-17T00:00:00.000+01:00", "type":"Android", "locale":"en_GB"}' https://api.cloudflareclient.com/v0a737/reg | tee warp.json > /dev/null

sudo wg set wg0 peer '$CLOUDFLAREKEY' endpoint '$IPV4':51820 allowed-ips 172.16.0.0/24 > out.log 2> /dev/null
wg-quick down wg0 > out.log 2> /dev/null
wg-quick up wg0 > out.log 2> /dev/null

clear
clear
clear

echo '[Interface]
Address = 172.16.0.2/12
DNS = 1.1.1.1
PrivateKey = '$PRIVATEKEY'

[Peer]
PublicKey = '$CLOUDFLAREKEY'
AllowedIPs = 0.0.0.0/0
Endpoint = engage.cloudflareclient.com:2408' > client.conf

echo 'Wireguard has successfully installed in your VPS

Your PUBLICKEY is '$PUBLICKEY'
Your PRIVATEKEY is '$PRIVATEKEY'

_______________________

Your Client Config is:

[Interface]
Address = 172.16.0.2/12
DNS = 1.1.1.1
PrivateKey = '$PRIVATEKEY'

[Peer]
PublicKey = '$CLOUDFLAREKEY'
AllowedIPs = 0.0.0.0/0
Endpoint = engage.cloudflareclient.com:2408

_______________________

Special Thanks to PHC_Tipaklong for the tutorial
https://phcorner.net/threads/791583/'
