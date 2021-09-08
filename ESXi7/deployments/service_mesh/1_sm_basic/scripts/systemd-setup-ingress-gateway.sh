#!/bin/sh

#################################
#         Setup SystemD         #
#################################

echo "enabling meshgateway service"
#Create Systemd Config for Consul Mesh Gateway
cat <<EOF > /etc/systemd/system/ingressgateway.service
[Unit]
Description=Envoy
After=network-online.target
Wants=consul.service
[Service]
ExecStart=/usr/bin/consul connect envoy -gateway=ingress -envoy-binary /usr/bin/envoy -register -service ingress-service -address '{{ GetInterfaceIP "ens160" }}:8888'
Restart=always
RestartSec=5
StartLimitIntervalSec=0
[Install]
WantedBy=multi-user.target
EOF

#Enable the service
systemctl enable ingressgateway
service ingressgateway start

sleep 30

mkdir /tmp/rtlab

echo "Registering Services w/ Ingress Gateway"
#Create Systemd Config for Consul Mesh Gateway
cat <<EOF > /tmp/rtlab/service_defaults_web.hcl

Kind      = "service-defaults"
Name      = "web"
# Namespace = "default"
Protocol  = "http"
EOF

consul config write /tmp/rtlab/service_defaults_web.hcl > /tmp/rtlab/service_defaults_web.out


echo "Registering Services w/ Ingress Gateway"
#Create Systemd Config for Consul Mesh Gateway
cat <<EOF > /tmp/rtlab/ingress.hcl

Kind = "ingress-gateway"
Name = "ingress-service"

Listeners = [
 {
   Port = 8081
   Protocol = "tcp"
   Services = [
     {
       Name = "web"
     }
   ]
 },
 {
   Port = 8082
   Protocol = "tcp"
   Services = [
     {
       Name = "api"
     }
   ]
 }
]
EOF

consul config write /tmp/rtlab/ingress.hcl > /tmp/rtlab/ingress.out
