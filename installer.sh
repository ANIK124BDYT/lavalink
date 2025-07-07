#!/bin/bash

# ================================================
# 🚀 Lavalink VPS Auto Installer
# 👑 Made by ANIK124BD
# ================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function show_banner() {
  clear
  echo -e "${BLUE}"
  echo """
 █████╗ ███╗   ██╗██╗██╗  ██╗
██╔══██╗████╗  ██║██║██║ ██╔╝
███████║██╔██╗ ██║██║█████╔╝ 
██╔══██║██║╚██╗██║██║██╔═██╗ 
██║  ██║██║ ╚████║██║██║  ██╗
╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝
"""
  echo -e "${NC}"
  echo -e "${GREEN}👑 Lavalink VPS Manager - Made by ANIK124BD${NC}"
  echo -e "${YELLOW}===============================================${NC}"
  echo
}

function check_success {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✔️] $1 succeeded${NC}"
  else
    echo -e "${RED}[❌] $1 failed. Exiting...${NC}"
    exit 1
  fi
}

function install_lavalink() {
  show_banner
  echo -e "${YELLOW}🚀 Starting Lavalink Installation...${NC}"
  echo
  
  # Prompt for domain
  read -p "🌐 Enter your domain for Lavalink (e.g. lava.yourdomain.com): " USER_DOMAIN
  if [[ -z "$USER_DOMAIN" ]]; then
    echo -e "${RED}[❌] Domain cannot be empty. Exiting.${NC}"
    exit 1
  fi

  # Prompt for password
  read -sp "🔒 Enter your Lavalink password (input hidden): " USER_PASS
  echo
  if [[ -z "$USER_PASS" ]]; then
    echo -e "${RED}[❌] Password cannot be empty. Exiting.${NC}"
    exit 1
  fi

  echo -e "🔍 Checking if domain ${GREEN}$USER_DOMAIN${NC} points to this VPS..."

  MY_IP=$(curl -s ipv4.icanhazip.com)
  DOMAIN_IP=$(ping -c 1 "$USER_DOMAIN" | grep -oP '(?<=\().+?(?=\))' | head -1)

  if [[ "$MY_IP" != "$DOMAIN_IP" ]]; then
    echo -e "${RED}[❌] Domain does not point to this server IP ($MY_IP). Fix DNS first.${NC}"
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
  check_success "Config creation"

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
  echo -e "${YELLOW}===============================================${NC}"
  echo -e "🌐 URL         : ${GREEN}https://$USER_DOMAIN${NC}"
  echo -e "🔑 Password    : ${GREEN}$USER_PASS${NC}"
  echo -e "📁 Directory   : /root/lavalink"
  echo -e "🟢 Auto-Start  : Enabled (systemd)"
  echo -e "${YELLOW}===============================================${NC}"
}

function uninstall_lavalink() {
  show_banner
  echo -e "${RED}⚠️ Starting Lavalink Uninstallation...${NC}"
  
  echo -e "🛑 Stopping Lavalink service..."
  systemctl stop lavalink
  systemctl disable lavalink
  rm -f /etc/systemd/system/lavalink.service
  systemctl daemon-reload
  check_success "Service removal"

  echo -e "🗑️ Removing Lavalink directory..."
  rm -rf /root/lavalink
  check_success "Directory removal"

  echo -e "🌐 Removing NGINX configuration..."
  rm -f /etc/nginx/sites-available/lavalink
  rm -f /etc/nginx/sites-enabled/lavalink
  nginx -t && systemctl restart nginx
  check_success "NGINX config removal"

  echo -e "${GREEN}✅ Lavalink successfully uninstalled!${NC}"
}

# Main menu
show_banner
echo -e "${YELLOW}Select an option:${NC}"
echo -e "1) Install Lavalink"
echo -e "2) Uninstall Lavalink"
echo -e "3) Exit"
echo
read -p "Enter your choice (1-3): " choice

case $choice in
  1)
    install_lavalink
    ;;
  2)
    uninstall_lavalink
    ;;
  3)
    echo -e "${BLUE}Exiting...${NC}"
    exit 0
    ;;
  *)
    echo -e "${RED}Invalid choice. Exiting...${NC}"
    exit 1
    ;;
esac
