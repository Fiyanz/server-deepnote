# 🚀 Remote SSH Documentation: Deepnote

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](https://unlicense.org/)
[![GitHub](https://img.shields.io/badge/GitHub-Fiyanz%2Fremote--server--deepnote-181717?logo=github)](https://github.com/Fiyanz/remote-server-deepnote)

Dokumentasi ini menjelaskan prosedur teknis untuk membangun koneksi SSH yang stabil dan rendah latensi dari mesin lokal linux ke lingkungan kontainer Deepnote menggunakan Dropbear dan Pinggy.

---

## 📋 Prasyarat

- **Sistem Operasi Lokal**: Linux
- **Akun Deepnote** dengan mesin yang sedang berjalan (Running)
- **Akses internet** stabil

---

## 🛠️ Langkah 1: Konfigurasi Server (Deepnote)

Karena Deepnote menggunakan arsitektur kontainer tanpa `systemd`, kita menggunakan **Dropbear** sebagai alternatif SSH server yang ringan dan kompatibel.

### 1.0 Pilih Metode Setup

**Opsi 1: Menggunakan Script Otomatis (Direkomendasikan)**

Clone repository dan jalankan script all-in-one:

```bash
git clone https://github.com/Fiyanz/remote-server-deepnote.git
cd remote-server-deepnote
chmod +x setup.sh
./setup.sh
```

Script akan secara otomatis:
- Menginstal dependencies (net-tools, dropbear, git)
- Mengatur password root (akan diminta input)
- Menjalankan Dropbear SSH server
- Memverifikasi port 22
- Membuat Pinggy tunnel dan menampilkan URL koneksi

**Opsi 2: Setup Manual**

Ikuti langkah-langkah berikut jika Anda ingin melakukan konfigurasi secara manual atau memahami setiap tahap proses.

---

### 1.1 Update & Set Password

Tentukan kredensial masuk untuk user root:

```bash
apt update && apt install -y net-tools
passwd root
```

### 1.2 Instalasi & Aktivasi Dropbear

Jalankan Dropbear pada port 22 secara manual (menggantikan OpenSSH yang sering terkendala masalah `chroot` di Docker):

```bash
apt install -y dropbear
```
Terus
```bash
/usr/sbin/dropbear -p 22 -R -E &
```

**Parameter yang digunakan:**
- `-p 22`: Listen pada port 22
- `-R`: Disable host key check
- `-E`: Log ke stderr
- `&`: Jalankan di background

### 1.3 Verifikasi Port

Pastikan port 22 telah berstatus LISTEN:

```bash
netstat -tuln | grep :22
```

Output yang diharapkan:
```
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN
```

---

## 🌐 Langkah 2: Membangun Tunnel (Pinggy)

**Catatan:** Jika Anda menggunakan script otomatis (`setup.sh`), langkah ini sudah otomatis dijalankan. Langkah manual di bawah hanya untuk Opsi 2 (Setup Manual).

Gunakan **Pinggy** untuk mengekspos port 22 internal ke alamat publik melalui protokol TCP.

### Pilih Metode Berdasarkan Akun:

#### Opsi A: Akun Gratis (Anonymous)

Untuk pengguna tanpa akun Pinggy:

```bash
ssh -p 443 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -R0:localhost:22 tcp@ap.free.pinggy.io
```

**Batasan:**
- Tunnel kedaluwarsa setiap **60 menit**
- Port dan URL berubah setiap kali tunnel dibuat ulang
- Tidak ada persistensi

#### Opsi B: Akun Login (Direkomendasikan)

Untuk pengguna yang sudah login ke Pinggy (dapatkan token di [pinggy.io](https://pinggy.io)):

```bash
ssh -p 443 -R0:localhost:22 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 [YOUR_TOKEN]+tcp@free.pinggy.io
```

**Contoh:**
```bash
ssh -p 443 -R0:localhost:22 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 gEhqfSSEC9D+tcp@free.pinggy.io
```

**Keuntungan:**
- Durasi tunnel lebih panjang
- URL lebih konsisten
- Akses ke fitur tambahan
- Monitoring dan statistik

### Informasi Umum

Setelah tunnel terbentuk, salin alamat yang muncul:
- Contoh output: `tcp://smxtp-13-220-9-250.a.free.pinggy.link:41149`

**Parameter yang digunakan:**
- `-p 443`: Koneksi ke Pinggy melalui port 443
- `-R0:localhost:22`: Reverse tunnel dari port random ke localhost:22
- `-o StrictHostKeyChecking=no`: Skip verifikasi host key
- `-o ServerAliveInterval=30`: Keep-alive setiap 30 detik

---

## 💻 Langkah 3: Koneksi dari Komputer Lokal

Buka terminal di Pop!_OS Anda dan gunakan perintah SSH standar:

```bash
# Format: ssh -p [PORT] root@[ALAMAT]
ssh -p 41149 root@xxxx.a.free.pinggy.link
```

**Tips:**
- Ganti `41149` dengan port yang diberikan Pinggy
- Ganti alamat dengan URL yang diberikan Pinggy
- Masukkan password root yang telah Anda set di Langkah 1.1

---

## ⚠️ Troubleshooting & Batasan

| Kendala | Penyebab | Solusi |
|---------|----------|--------|
| `systemctl: command not found` | Deepnote tidak menggunakan `systemd` (PID 1) | Gunakan perintah `service` atau jalankan binary aplikasi secara langsung |
| `chroot: operation not permitted` | Batasan keamanan Docker pada OpenSSH | Gunakan Dropbear yang tidak memerlukan fitur chroot/privilege separation |
| `Connection closed` | Sesi tunnel Pinggy (60 menit) telah berakhir | Jalankan ulang perintah tunnel di Langkah 2 untuk mendapatkan port baru |
| Layanan Berat (Lag) | Latensi geografis antar benua | Gunakan VS Code Remote SSH untuk pengalaman coding yang lebih responsif |

---

## 💡 Tips

### Keep-Alive
Jangan menutup tab browser Deepnote agar proses latar belakang tidak dimatikan oleh sistem.

### Workflow Optimal
- Gunakan `scp` untuk transfer file:
  ```bash
  scp -P 41149 file.txt root@smxtp-13-220-9-250.a.free.pinggy.link:/root/
  ```
- Sambungkan VS Code melalui **Remote-SSH extension** menggunakan alamat Pinggy yang aktif

### Auto-Reconnect
Buat script untuk monitoring dan auto-restart tunnel saat terputus (lihat bagian Script Automation).

---

## 🔧 Script Automation

Script lengkap yang menggabungkan setup SSH server dan pembuatan tunnel dalam satu file ([setup.sh](setup.sh)):

```bash
#!/bin/bash
# Complete Setup: SSH Server + Pinggy Tunnel untuk Deepnote

echo "=========================================="
echo "  Remote SSH Setup - Deepnote Complete   "
echo "=========================================="

echo "[1/5] Updating system dan instalasi dependencies..."
apt update && apt install -y net-tools dropbear git

echo "[2/5] Setting root password..."
passwd root

echo "[3/5] Starting Dropbear SSH server..."
/usr/sbin/dropbear -p 22 -R -E &

echo "[4/5] Verifying port 22..."
sleep 2
netstat -tuln | grep :22

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
```

Jalankan dengan:
```bash
chmod +x setup-complete.sh
./setup-complete.sh
```

**Tips:** Untuk menggunakan token secara langsung tanpa prompt, edit script dan ganti perintah tunnel dengan token Anda.

---

## 📚 Referensi

- [Dropbear SSH Documentation](https://matt.ucc.asn.au/dropbear/dropbear.html)
- [Pinggy Documentation](https://pinggy.io/docs/)
- [Docker Networking](https://docs.docker.com/network/)

---

## 📝 Changelog

### v1.0.0 (2026-01-19)
- Initial documentation
- Setup menggunakan Dropbear sebagai SSH server
- Integrasi dengan Pinggy untuk tunnel
- Troubleshooting guide dan automation scripts

---

## 📄 License

This project is released into the **public domain** under [The Unlicense](LICENSE).

**What this means:**
- ✅ Use for any purpose (commercial or non-commercial)
- ✅ Modify and distribute freely
- ✅ No attribution required
- ✅ No restrictions whatsoever
- 🌐 Dedicated to the public domain

You are free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

For more information, see <https://unlicense.org>

---

## ⚖️ Disclaimer

Dokumentasi ini disediakan "sebagaimana adanya" tanpa jaminan dalam bentuk apapun, baik tersurat maupun tersirat. Pengguna bertanggung jawab penuh atas segala risiko yang timbul dari penggunaan informasi dan instruksi yang terdapat dalam dokumentasi ini. Penulis tidak bertanggung jawab atas kerusakan, kehilangan data, atau konsekuensi lainnya yang mungkin terjadi akibat implementasi metode yang dijelaskan.

Penggunaan layanan pihak ketiga (Deepnote, Pinggy) tunduk pada syarat dan ketentuan masing-masing penyedia layanan.

---

*Last updated: January 19, 2026*