#!/bin/bash
# Bootstraps the EC2 instance so it is ready to receive the app from CI.
# This is the "Configuration as Code" step: rather than manually SSHing in
# and installing packages, the environment configures itself on first boot.
set -euxo pipefail

apt-get update -y
apt-get install -y python3-pip python3-venv git

mkdir -p /opt/app
chown ubuntu:ubuntu /opt/app

# systemd unit so the app restarts automatically, survives reboots, and
# can be restarted cleanly by the deployment pipeline.
cat > /etc/systemd/system/devops-app.service << 'EOF'
[Unit]
Description=DevOps Pipeline Demo Flask App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/app
ExecStart=/opt/app/venv/bin/python3 /opt/app/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable devops-app
