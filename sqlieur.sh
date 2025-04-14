#!/bin/bash

# Script: sqlieur.sh
# Deskripsi: Mengumpulkan URL potensial dari domain target dan menguji SQL Injection dengan sqlmap
# Penggunaan: ./sqlieur.sh [options] <target_domain>
# Contoh: ./sqlieur.sh -o ./output -p http://127.0.0.1:8080 target.com

# Warna untuk output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Default values
OUTPUT_DIR="."
PROXY=""
THREADS=5
TIMEOUT=5
SQLMAP_LEVEL=3
SQLMAP_RISK=2
SQLMAP_TAMPER="between,space2comment,randomcase"
VERBOSE=false
RATE_LIMIT=10
RETRY_COUNT=3
CONNECTION_TIMEOUT=10
READ_TIMEOUT=10
WRITE_TIMEOUT=10
TOTAL_TIMEOUT=30
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
COOKIE=""
CUSTOM_HEADERS=""
DELAY=1

# Fungsi untuk logging dengan warna
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] $message${NC}" | tee -a "$LOG_FILE"
}

# Fungsi untuk menampilkan header
print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}  Sqlieur - Automated Vulnerability Scan - betmenXsec  ${NC}"
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${GREEN}Target: $TARGET${NC}"
    echo -e "${GREEN}Output Directory: $OUTPUT_DIR${NC}"
    echo -e "${GREEN}Proxy: ${PROXY:-None}${NC}"
    echo -e "${GREEN}Threads: $THREADS${NC}"
    echo -e "${GREEN}Timeout: $TIMEOUT${NC}\n"
}

# Fungsi untuk validasi domain
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
        log "$RED" "ERROR: Format domain tidak valid"
        exit 1
    fi
}

# Fungsi untuk menampilkan progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local progress=$((width * percentage / 100))
    printf "\r[%-${width}s] %d%%" "$(printf '#%.0s' $(seq 1 $progress))" "$percentage"
}

# Fungsi untuk cek dan install dependensi
check_and_install_dependencies() {
    local deps=("katana" "gau" "httpx" "sqlmap")
    local go_installed=false
    local pip_installed=false

    # Cek apakah Go terinstall
    if ! command -v go &> /dev/null; then
        log "$YELLOW" "Go tidak ditemukan. Menginstall Go..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y golang
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install go
        else
            log "$RED" "OS tidak didukung untuk instalasi otomatis Go. Install Go secara manual."
            exit 1
        fi
        go_installed=true
    fi

    # Cek apakah pip terinstall
    if ! command -v pip3 &> /dev/null; then
        log "$YELLOW" "pip3 tidak ditemukan. Menginstall pip3..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y python3-pip
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install python
        else
            log "$RED" "OS tidak didukung untuk instalasi otomatis pip3. Install pip3 secara manual."
            exit 1
        fi
        pip_installed=true
    fi

    # Cek dan install dependensi
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "$YELLOW" "$dep tidak ditemukan. Menginstall $dep..."
            case $dep in
                "katana")
                    go install github.com/projectdiscovery/katana/cmd/katana@latest 2>> "$LOG_FILE"
                    sudo mv ~/go/bin/katana /usr/local/bin/ 2>> "$LOG_FILE"
                    ;;
                "gau")
                    go install github.com/lc/gau/v2/cmd/gau@latest 2>> "$LOG_FILE"
                    sudo mv ~/go/bin/gau /usr/local/bin/ 2>> "$LOG_FILE"
                    ;;
                "httpx")
                    go install github.com/projectdiscovery/httpx/cmd/httpx@latest 2>> "$LOG_FILE"
                    sudo mv ~/go/bin/httpx /usr/local/bin/ 2>> "$LOG_FILE"
                    ;;
                "sqlmap")
                    pip3 install sqlmap 2>> "$LOG_FILE"
                    ;;
            esac
            if command -v "$dep" &> /dev/null; then
                log "$GREEN" "$dep berhasil diinstall."
            else
                log "$RED" "Gagal menginstall $dep. Periksa $LOG_FILE untuk detail."
                exit 1
            fi
        else
            log "$GREEN" "$dep sudah terinstall."
        fi
    done
}

# Fungsi untuk menampilkan bantuan
show_help() {
    echo -e "${BLUE}SQLi Scanner - Automated Vulnerability Scanner${NC}"
    echo -e "Penggunaan: $0 [options] <target_domain>"
    echo -e "\nOptions:"
    echo -e "  -h, --help              Tampilkan bantuan"
    echo -e "  -o, --output DIR        Tentukan direktori output"
    echo -e "  -p, --proxy PROXY       Gunakan proxy (format: http://ip:port)"
    echo -e "  -t, --threads NUM       Jumlah thread (default: 5)"
    echo -e "  -T, --timeout SEC       Timeout dalam detik (default: 5)"
    echo -e "  -l, --level LEVEL       Level sqlmap (1-5, default: 3)"
    echo -e "  -r, --risk RISK         Risk sqlmap (1-3, default: 2)"
    echo -e "  -m, --tamper TAMPER     Tamper script sqlmap"
    echo -e "  -v, --verbose           Mode verbose"
    echo -e "  -u, --user-agent UA     Custom user agent"
    echo -e "  -c, --cookie COOKIE     Custom cookie"
    echo -e "  -H, --header HEADER     Custom header"
    echo -e "  -d, --delay SEC         Delay antara request (default: 1)"
    echo -e "  -R, --retry NUM         Jumlah retry (default: 3)"
    echo -e "  -L, --rate-limit NUM    Rate limit per detik (default: 10)"
    exit 0
}

# Fungsi untuk memastikan URL memiliki protokol
ensure_protocol() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo "http://$url"
    else
        echo "$url"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -p|--proxy)
            PROXY="$2"
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -T|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -l|--level)
            SQLMAP_LEVEL="$2"
            shift 2
            ;;
        -r|--risk)
            SQLMAP_RISK="$2"
            shift 2
            ;;
        -m|--tamper)
            SQLMAP_TAMPER="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -u|--user-agent)
            USER_AGENT="$2"
            shift 2
            ;;
        -c|--cookie)
            COOKIE="$2"
            shift 2
            ;;
        -H|--header)
            CUSTOM_HEADERS="$2"
            shift 2
            ;;
        -d|--delay)
            DELAY="$2"
            shift 2
            ;;
        -R|--retry)
            RETRY_COUNT="$2"
            shift 2
            ;;
        -L|--rate-limit)
            RATE_LIMIT="$2"
            shift 2
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

# Cek apakah domain diberikan
if [ -z "$TARGET" ]; then
    show_help
    exit 1
fi

# Validasi domain
validate_domain "$TARGET"

# Buat direktori output jika tidak ada
mkdir -p "$OUTPUT_DIR"

# Variabel
OUTPUT_FILE="$OUTPUT_DIR/sqli.$TARGET.txt"
LOG_FILE="$OUTPUT_DIR/sqli_scan_$TARGET.log"
TEMP_URLS="$OUTPUT_DIR/temp_urls_$TARGET.txt"
FILTERED_URLS="$OUTPUT_DIR/filtered_urls_$TARGET.txt"

# Bersihkan log file sebelumnya jika ada
> "$LOG_FILE"

# Tampilkan header
print_header

# Set proxy jika diberikan
if [ -n "$PROXY" ]; then
    export http_proxy="$PROXY"
    export https_proxy="$PROXY"
fi

# Set verbose mode
if [ "$VERBOSE" = true ]; then
    set -x
fi

# Cek dan install dependensi
log "$BLUE" "Memeriksa dan menginstall dependensi..."
check_and_install_dependencies
log "$GREEN" "Semua dependensi siap digunakan."

# Langkah 1: Mengumpulkan URL dengan katana dan gau
log "$BLUE" "Mengumpulkan URL dari $TARGET..."
TARGET_URL=$(ensure_protocol "$TARGET")
echo "$TARGET_URL" | xargs -P 2 -I {} sh -c "katana -u {} -d 5 -silent -rate-limit $RATE_LIMIT -timeout $TIMEOUT && gau {} --subs --providers wayback,commoncrawl,otx,urlscan" 2>> "$LOG_FILE" | sort -u > "$TEMP_URLS"
if [ ! -s "$TEMP_URLS" ]; then
    log "$RED" "ERROR: Tidak ada URL yang ditemukan untuk $TARGET."
    rm -f "$TEMP_URLS"
    exit 1
fi
log "$GREEN" "Selesai mengumpulkan $(wc -l < "$TEMP_URLS") URL."

# Langkah 2: Membersihkan URL (hapus port) dan memfilter
log "$BLUE" "Memfilter URL untuk ekstensi dinamis dan parameter query..."
cat "$TEMP_URLS" | sed 's/:[0-9]\{1,5\}//' | grep -aiE '\.(php|asp|aspx|jsp|cfm|pl|py)' | grep -a "[=?&]" > "$FILTERED_URLS"
if [ ! -s "$FILTERED_URLS" ]; then
    log "$YELLOW" "WARNING: Tidak ada URL yang cocok dengan filter."
    rm -f "$TEMP_URLS" "$FILTERED_URLS"
    exit 1
fi
log "$GREEN" "Selesai memfilter, ditemukan $(wc -l < "$FILTERED_URLS") URL."

# Langkah 3: Verifikasi URL dengan httpx
log "$BLUE" "Memverifikasi URL aktif dengan httpx..."
cat "$FILTERED_URLS" | httpx -silent -timeout "$TIMEOUT" -threads "$THREADS" -follow-redirects -retries "$RETRY_COUNT" -H "User-Agent: $USER_AGENT" ${COOKIE:+-H "Cookie: $COOKIE"} ${CUSTOM_HEADERS:+-H "$CUSTOM_HEADERS"} 2>> "$LOG_FILE" | sort -u > "$OUTPUT_FILE"

# Langkah 4: Menjalankan sqlmap
log "$BLUE" "Menjalankan sqlmap untuk pengujian SQL Injection..."
if [ -s "$OUTPUT_FILE" ]; then
    sqlmap -m "$OUTPUT_FILE" \
        --risk="$SQLMAP_RISK" \
        --level="$SQLMAP_LEVEL" \
        --random-agent \
        --threads="$THREADS" \
        --batch \
        --tamper="$SQLMAP_TAMPER" \
        --dbs \
        --smart \
        --timeout="$TIMEOUT" \
        --retries="$RETRY_COUNT" \
        --delay="$DELAY" \
        ${PROXY:+--proxy="$PROXY"} \
        ${COOKIE:+--cookie="$COOKIE"} \
        ${CUSTOM_HEADERS:+--headers="$CUSTOM_HEADERS"} \
        --crawl=5 \
        --forms \
        2>> "$LOG_FILE"

    if [ $? -eq 0 ]; then
        log "$GREEN" "Pengujian sqlmap selesai."
    else
        log "$RED" "ERROR: sqlmap gagal. Periksa $LOG_FILE untuk detail."
    fi
else
    log "$RED" "ERROR: Tidak ada URL yang dapat diuji."
    exit 1
fi

# Bersihkan file sementara
rm -f "$TEMP_URLS" "$FILTERED_URLS"
log "$GREEN" "Skrip selesai. Hasil disimpan di $OUTPUT_FILE dan log di $LOG_FILE."

exit 0 
