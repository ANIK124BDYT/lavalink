# 🚀 Lavalink VPS Auto Installer

A fully automated script to install and manage Lavalink on your Ubuntu VPS, complete with SSL, NGINX reverse proxy, and systemd support.

> 👑 Made with ❤️ by **ANIK124BD**

---

## 📦 Features

- Auto installs **Java 17**, **NGINX**, **Lavalink**
- Auto configures **systemd** service
- Reverse proxy with **NGINX**
- Automatic **SSL certificate** using Let's Encrypt
- Fully **interactive** prompts
- Supports **uninstallation** option

---

## 🛠 Requirements

- Ubuntu VPS (recommended Ubuntu 20.04 or 22.04)
- Root access (`sudo` or root login)
- A domain name (e.g., `lava.yourdomain.com`)
- DNS A record must point your domain to the VPS IP

---


## 📥 One-Line Installation (Recommended)

Run this command on your VPS:

```bash
bash <(curl -s https://raw.githubusercontent.com/ANIK124BDYT/lavalink/main/installer.sh)

