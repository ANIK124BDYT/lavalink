#!/bin/bash

# ================================================
# 🚀 Lavalink VPS Auto Installer
# 👑 Made by ANIK124BD
# ================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function check_success {
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ $1 failed. Exiting...${NC}"
    exit 1
  fi
}

clear
echo -e "${GREEN}👑 Lavalink Installer - Made by ANIK124BD${NC}"

# Prompt for domain
read -p "🌐 Enter your domain for Lavalink (e.g. lava.yourdomain.com): " USER_DOMAIN
if [[ -z "$USER_DOMAIN" ]]; then
  echo -e "${RED}❌ Domain cannot be empty. Exiting.${NC}"
  exit 1
fi

# Prompt for password
read -sp "🔒 Enter your Lavalink password (input hidden): " USER_PASS
echo
if [[ -z "$USER_PASS" ]]; then
  echo -e "${RED}❌ Password cannot be empty. Exiting.${NC}"
  exit 1
fi

echo -e "🔍 Checking if domain ${GREEN}$USER_DOMAIN${NC} points to this VPS..."

MY_IP=$(curl -s ipv4.icanhazip.com)
DOMAIN_IP=$(ping -c 1 "$USER_DOMAIN" | grep -oP '(?<=).+?(?=)' | head -1)

if [[ "$MY_IP" != "$DOMAIN_IP" ]]; then
  echo -e "${RED}❌ Domain does not point to this server IP ($MY_IP). Fix DNS first.${NC}"
  exit 1
fi

echo -e "⚙️ Updating system..."
apt update && apt upgrade -y
check_success "System update"

echo -e "☕ Installing Java 17..."
apt install openjdk-17-jre -y
check_success "Java installation"

echo -e "📂 Setting up Lavalink directory..."
mkdir -p /root/lavalink
cd /root/lavalink || exit

echo -e "⬇️ Downloading Lavalink JAR..."
wget https://github.com/freyacodes/Lavalink/releases/latest/download/Lavalink.jar -O Lavalink.jar
check_success "Lavalink download"

echo -e "📝 Creating Lavalink config..."
cat <<EOL > application.yml
server:
  port: 2333
  address: 127.0.0.1

lavalink:
  server:
    password: "$USER_PASS"
    sources:
      youtube: true
      bandcamp: true
      soundcloud: true
      twitch: true
      vimeo: true
      http: true
      local: false

metrics:
  prometheus:
    enabled: false
    endpoint: /metrics

logging:
  level:
    root: INFO
EOL

echo -e "🔧 Creating systemd service..."
cat <<EOL > /etc/systemd/system/lavalink.service
[Unit]
Description=Lavalink Service by ANIK124BD
After=network.target

[Service]
User=root
WorkingDirectory=/root/lavalink
ExecStart=/usr/bin/java -jar Lavalink.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable lavalink
systemctl start lavalink
check_success "Lavalink service start"

echo -e "🌐 Installing NGINX + SSL tools..."
apt install nginx certbot python3-certbot-nginx -y
check_success "NGINX and Certbot install"

echo -e "📦 Creating NGINX config for $USER_DOMAIN..."
cat <<EOL > /etc/nginx/sites-available/lavalink
server {
    listen 80;
    server_name $USER_DOMAIN;

    location / {
        proxy_pass http://localhost:2333;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOL

ln -sf /etc/nginx/sites-available/lavalink /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx
check_success "NGINX setup"

echo -e "🔐 Requesting SSL certificate..."
certbot --nginx -d $USER_DOMAIN --non-interactive --agree-tos -m admin@$USER_DOMAIN
check_success "SSL setup"

echo -e "${GREEN}✅ Lavalink successfully installed!${NC}"
echo "----------------------------------------"
echo -e "🌐 URL         : ${GREEN}https://$USER_DOMAIN${NC}"
echo -e "🔑 Password    : ${GREEN}$USER_PASS${NC}"
echo -e "📁 Directory   : /root/lavalink"
echo -e "🟢 Auto-Start  : Enabled (systemd)"
echo -e "👑 Installer   : ANIK124BD"
echo "----------------------------------------"
