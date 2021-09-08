#!/bin/sh

# Consul bind address templating options: https://www.consul.io/docs/agent/options#_bind
# '{{ GetPrivateInterfaces | include "network" "10.0.0.0/8" | attr "address" }}'
# '{{ GetInterfaceIP "eth0" }}'
# '{{ GetAllInterfaces | include "name" "^eth" | include "flags" "forwardable|up" | attr "address" }}'

echo "enabling consul service"
#Create Systemd Config for Consul
cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target

[Service]
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -bind '{{ GetInterfaceIP "ens160" }}' -config-dir=/etc/consul.d/
ExecReload=/usr/bin/consul reload
KillMode=process
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

#Enable the service
systemctl enable consul
service consul start
