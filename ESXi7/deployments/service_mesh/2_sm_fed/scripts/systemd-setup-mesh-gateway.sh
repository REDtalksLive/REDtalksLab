#!/bin/sh

#################################
#         Setup SystemD         #
#################################

echo "enabling meshgateway service"
#Create Systemd Config for Consul Mesh Gateway
cat <<EOF > /etc/systemd/system/meshgateway.service
[Unit]
Description=Envoy
After=network-online.target
Wants=consul.service
[Service]
ExecStart=/usr/bin/consul connect envoy -mesh-gateway  -envoy-binary /usr/bin/envoy -register -service ${service_id} -address ${ip_addr}:443 -wan-address ${ip_addr}:443 -bind-address "public=${ip_addr}:443" -admin-bind 127.0.0.1:21000
Restart=always
RestartSec=5
StartLimitIntervalSec=0
[Install]
WantedBy=multi-user.target
EOF

#Enable the service
systemctl enable meshgateway
service meshgateway start


