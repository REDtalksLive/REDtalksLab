#!/bin/sh

#################################
#         Setup SystemD         #
#################################

echo "enabling consul-tf-sync service"

#Create Systemd Config for Consul Terraform Sync
cat << EOF > /etc/systemd/system/consul-tf-sync.service
[Unit]
Description="HashiCorp Consul Terraform Sync - A Network Infra Automation solution"
Documentation=https://www.consul.io/
Requires=consul.service
After=consul.service

[Service]
User=consul
Group=consul
ExecStart=/usr/bin/consul-terraform-sync -config-file=/etc/consul-tf-sync.d/consul-tf-sync.hcl
KillMode=process
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

#Enable the service
systemctl enable consul-tf-sync
service consul-tf-sync start
