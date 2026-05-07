#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y git python3 python3-pip python3-venv python3-dev default-libmysqlclient-dev build-essential pkg-config nginx

cd /home/azureuser

git clone https://github.com/AydinTokuslu/azure-capstone-2026.git
chown -R azureuser:azureuser /home/azureuser/azure-capstone-2026

python3 -m venv /opt/capstone-venv
/opt/capstone-venv/bin/pip install --upgrade pip setuptools wheel
/opt/capstone-venv/bin/pip install -r /home/azureuser/azure-capstone-2026/requirements.txt

cd /home/azureuser/azure-capstone-2026/src

/opt/capstone-venv/bin/python manage.py check
/opt/capstone-venv/bin/python manage.py collectstatic --noinput
/opt/capstone-venv/bin/python manage.py migrate

cat >/etc/systemd/system/capstone.service <<'EOF'
[Unit]
Description=Capstone Django Gunicorn
After=network.target

[Service]
User=azureuser
Group=www-data
WorkingDirectory=/home/azureuser/azure-capstone-2026/src
EnvironmentFile=/home/azureuser/azure-capstone-2026/.env
ExecStart=/opt/capstone-venv/bin/gunicorn cblog.wsgi:application --bind 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now capstone