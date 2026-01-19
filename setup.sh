#!/bin/bash
# Complete Setup: SSH Server + Pinggy Tunnel untuk Deepnote
# Script ini menggabungkan setup SSH server dan pembuatan tunnel

echo "=========================================="
echo "  Remote SSH Setup - Deepnote Complete   "
echo "=========================================="
echo ""

# Step 1: Update & Install Dependencies
echo "[1/5] Updating system dan instalasi dependencies..."
apt update && apt install -y net-tools dropbear git

# Step 2: Set Root Password
echo ""
echo "[2/5] Setting root password..."
echo "Masukkan password untuk root:"
passwd root

# Step 3: Start Dropbear SSH Server
echo ""
echo "[3/5] Starting Dropbear SSH server..."
/usr/sbin/dropbear -p 22 -R -E &

# Step 4: Verify Port
echo ""
echo "[4/5] Verifying port 22..."
sleep 2
netstat -tuln | grep :22

if [ $? -eq 0 ]; then
    echo "✓ Dropbear is running on port 22!"
else
    echo "✗ Error: Port 22 is not listening"
    exit 1
fi

# Step 5: Create Pinggy Tunnel
echo ""
echo "[5/5] Creating Pinggy tunnel..."
echo "Salin URL dan port yang muncul untuk koneksi SSH!"
echo ""
echo "Pilih metode:"
echo "1. Akun gratis (60 menit): tcp@ap.free.pinggy.io"
echo "2. Akun login: [TOKEN]+tcp@free.pinggy.io"
echo ""
read -p "Masukkan pilihan (1/2): " choice

if [ "$choice" == "2" ]; then
    read -p "Masukkan token Pinggy Anda: " token
    ssh -p 443 -R0:localhost:22 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 ${token}+tcp@free.pinggy.io
else
    ssh -p 443 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -R0:localhost:22 tcp@ap.free.pinggy.io
fi
