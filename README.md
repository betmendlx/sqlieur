# Sqlieur - Automated SQL Vulnerability Scanner

## Deskripsi
Sqlieur adalah alat otomatis untuk mendeteksi kerentanan SQL Injection pada aplikasi web. Alat ini mengumpulkan URL dari berbagai sumber dan melakukan pengujian menggunakan sqlmap.

## Fitur Utama
- Pengumpulan URL otomatis menggunakan katana dan gau
- Filtering URL berdasarkan ekstensi dinamis dan parameter query
- Verifikasi URL aktif menggunakan httpx
- Pengujian SQL Injection menggunakan sqlmap
- Instalasi dependensi otomatis
- Logging dengan warna
- Pembersihan file sementara
- Dukungan proxy dan custom headers
- Rate limiting dan delay
- Crawling dan form testing

## Persyaratan Sistem
- Linux/macOS
- Go >= 1.16
- Python >= 3.7
- pip3
- Virtual Environment (direkomendasikan)
- Akses root/sudo (untuk instalasi dependensi)

## Instalasi
1. Clone repository:
```bash
git clone https://github.com/bermendlx/sqlieur.git
cd sqlieur
```

2. Buat dan aktifkan virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
```

3. Install dependensi Python:
```bash
pip install -r requirements.txt
```

4. Install Go tools:
```bash
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
```

5. Berikan permission eksekusi:
```bash
chmod +x sqlieur.sh
```

## Penggunaan
```bash
./sqlieur.sh [options] <target_domain>

Options:
  -h, --help              Tampilkan bantuan
  -o, --output DIR        Tentukan direktori output
  -p, --proxy PROXY       Gunakan proxy (format: http://ip:port)
  -t, --threads NUM       Jumlah thread (default: 5)
  -T, --timeout SEC       Timeout dalam detik (default: 5)
  -l, --level LEVEL       Level sqlmap (1-5, default: 3)
  -r, --risk RISK         Risk sqlmap (1-3, default: 2)
  -m, --tamper TAMPER     Tamper script sqlmap
  -v, --verbose           Mode verbose
  -u, --user-agent UA     Custom user agent
  -c, --cookie COOKIE     Custom cookie
  -H, --header HEADER     Custom header
  -d, --delay SEC         Delay antara request (default: 1)
  -R, --retry NUM         Jumlah retry (default: 3)
  -L, --rate-limit NUM    Rate limit per detik (default: 10)
```

## Contoh Penggunaan
```bash
# Penggunaan dasar
./sqlieur.sh target.com

# Dengan proxy
./sqlieur.sh -p http://127.0.0.1:8080 target.com

# Dengan custom output directory
./sqlieur.sh -o /path/to/output target.com

# Dengan custom thread dan timeout
./sqlieur.sh -t 10 -T 10 target.com

# Dengan custom level dan risk
./sqlieur.sh -l 4 -r 3 target.com

# Dengan custom user agent dan cookie
./sqlieur.sh -u "Mozilla/5.0" -c "session=123" target.com

# Dengan rate limiting dan delay
./sqlieur.sh -L 5 -d 2 target.com
```

## Output
- `sqli.<target>.txt`: File berisi URL yang akan diuji
- `sqli_scan_<target>.log`: File log proses scanning
- Hasil sqlmap akan ditampilkan di terminal

## Keamanan
- Gunakan dengan bijak dan hanya pada target yang Anda miliki izin
- Jangan gunakan untuk aktivitas ilegal
- Gunakan proxy untuk scanning anonim
- Sesuaikan rate limiting untuk menghindari DoS
- Gunakan virtual environment untuk isolasi dependensi

## Kontribusi
Silakan buat pull request untuk kontribusi. Pastikan untuk:
1. Mengikuti standar koding
2. Menambahkan dokumentasi yang diperlukan
3. Menjalankan tes sebelum submit
4. Memperbarui versi dan changelog

## Changelog
### v1.0.0 (2025-04-14)
- Rilis awal
- Fitur dasar scanning SQL Injection
- Dukungan untuk katana, gau, httpx, dan sqlmap
- Logging dengan warna
- Pembersihan file sementara

### v1.1.0 (2025-04-14)
- Penambahan dukungan proxy
- Penambahan custom headers
- Penambahan rate limiting
- Penambahan delay
- Perbaikan bug dan optimasi

## Lisensi
MIT License

## Penafian
Alat ini hanya untuk tujuan edukasi dan pengujian keamanan. Penggunaan untuk aktivitas ilegal adalah tanggung jawab pengguna.

## Kontak
- Email: betmen0x0@proton.me
- Twitter: @betmen0x0 
