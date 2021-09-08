#!/bin/sh

#################################
#         Setup SystemD         #
#################################

echo "enabling Minikube service"
#Create Systemd Config for Consul
cat << EOF > /etc/systemd/system/minikube.service
[Unit]
Description="Minikube - just like a kube, but mini."
Documentation=https://minikube.sigs.k8s.io/docs/start/
Requires=network-online.target
After=network-online.target

[Service]
User=debian
Group=debian
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/minikube start
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/usr/bin/minikube stop
KillMode=process
Restart=no
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

#Enable the service
systemctl enable minikube
service minikube start
