#!/bin/bash
# Complete Setup: SSH Server + Tunnel (Pinggy/Ngrok) untuk Deepnote
# Script ini menggabungkan setup SSH server dan pembuatan tunnel

echo "=========================================="
echo "  Remote SSH Setup - Deepnote Complete   "
echo "=========================================="
echo ""

# Step 1: Update & Install Dependencies
echo "[1/6] Updating system dan instalasi dependencies..."
apt update && apt install -y net-tools dropbear git curl

# Step 2: Set Root Password
echo ""
echo "[2/6] Setting root password..."
read -p "Apakah Anda ingin mengubah password root? (y/n): " change_password

if [ "$change_password" == "y" ] || [ "$change_password" == "Y" ]; then
    echo "Masukkan password baru untuk root:"
    passwd root
else
    echo "Skip setting password. Menggunakan password yang sudah ada."
fi

# Step 3: Start Dropbear SSH Server
echo ""
echo "[3/6] Starting Dropbear SSH server..."
/usr/sbin/dropbear -p 22 -R -E &

# Step 4: Verify Port
echo ""
echo "[4/6] Verifying port 22..."
sleep 2
netstat -tuln | grep :22

if [ $? -eq 0 ]; then
    echo "✓ Dropbear is running on port 22!"
else
    echo "✗ Error: Port 22 is not listening"
    exit 1
fi

# Step 5: Choose Tunnel Method
echo ""
echo "[5/6] Pilih metode tunnel:"
echo "1. Pinggy (gratis/login)"
echo "2. Ngrok (memerlukan authtoken)"
echo ""
read -p "Masukkan pilihan (1/2): " tunnel_choice

# Step 6: Create Tunnel
echo ""
echo "[6/6] Creating tunnel..."

if [ "$tunnel_choice" == "2" ]; then
    # Ngrok Setup
    echo "Checking existing Ngrok sessions..."
    
    # Check if ngrok is already running
    if pgrep -x "ngrok" > /dev/null; then
        echo ""
        echo "⚠️  Ngrok sudah berjalan!"
        echo "Akun gratis Ngrok hanya mengizinkan 1 sesi simultan."
        echo ""
        echo "Pilihan:"
        echo "1. Matikan sesi ngrok yang lama dan buat baru"
        echo "2. Batal (gunakan dashboard untuk manage sesi: https://dashboard.ngrok.com/agents)"
        echo ""
        read -p "Pilih (1/2): " ngrok_action
        
        if [ "$ngrok_action" == "1" ]; then
            echo "Mematikan sesi ngrok yang lama..."
            pkill -9 ngrok
            sleep 2
            echo "✓ Sesi lama sudah dimatikan"
        else
            echo "Setup dibatalkan. Silakan matikan sesi ngrok lama secara manual."
            exit 0
        fi
    fi
    
    # Check if ngrok is installed
    if ! command -v ngrok &> /dev/null; then
        echo "Installing Ngrok..."
        curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
          | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
          && echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
          | tee /etc/apt/sources.list.d/ngrok.list \
          && apt update \
          && apt install -y ngrok
    else
        echo "✓ Ngrok sudah terinstal"
    fi
    
    # Check if authtoken already configured
    if [ ! -f /root/.config/ngrok/ngrok.yml ]; then
        echo ""
        echo "Dapatkan authtoken dari: https://dashboard.ngrok.com/get-started/your-authtoken"
        read -p "Paste authtoken Anda disini: " ngrok_token
        ngrok config add-authtoken $ngrok_token
        echo "✓ Authtoken berhasil disimpan"
    else
        echo "✓ Authtoken sudah dikonfigurasi sebelumnya"
    fi
    
    echo ""
    echo "Starting Ngrok tunnel on port 22..."
    echo "Salin URL yang muncul untuk koneksi SSH!"
    ngrok tcp 22
else
    # Pinggy Setup
    echo "Salin URL dan port yang muncul untuk koneksi SSH!"
    echo ""
    echo "Pilih metode Pinggy:"
    echo "1. Akun gratis (60 menit): tcp@ap.free.pinggy.io"
    echo "2. Akun login: [TOKEN]+tcp@free.pinggy.io"
    echo ""
    read -p "Masukkan pilihan (1/2): " pinggy_choice
    
    if [ "$pinggy_choice" == "2" ]; then
        read -p "Masukkan token Pinggy Anda: " token
        ssh -p 443 -R0:localhost:22 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 ${token}+tcp@free.pinggy.io
    else
        ssh -p 443 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -R0:localhost:22 tcp@ap.free.pinggy.io
    fi
fi
