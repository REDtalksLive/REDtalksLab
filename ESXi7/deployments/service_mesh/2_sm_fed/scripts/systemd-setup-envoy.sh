#!/bin/sh

#################################
#         Setup SystemD         #
#################################

echo "enabling envoy service"
#Create Systemd Config for Envoy
cat <<EOF > /etc/systemd/system/envoy.service
[Unit]
Description=Envoy
After=network-online.target
Wants=consul.service
[Service]
ExecStart=/usr/bin/consul connect envoy -sidecar-for ${service_id} -envoy-binary /usr/bin/envoy -- -l debug
Restart=always
RestartSec=5
StartLimitIntervalSec=0
[Install]
WantedBy=multi-user.target
EOF

#Enable the service
systemctl enable envoy
service envoy start
