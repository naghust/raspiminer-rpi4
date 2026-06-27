#!/usr/bin/env bash
LOG="/var/log/pizero-miner/cpuminer.log"
POOL_API="http://185.209.229.250:8081/api/client/bc1q4qvjln2sh89w28fj2agf760gez9a5rfpxjm50s"
MEMPOOL_API="https://mempool.space/api"
WORKER="rpi4"

fetch_pool() {
    curl -s --max-time 5 "$POOL_API" 2>/dev/null
}

fetch_network() {
    curl -s --max-time 5 "$MEMPOOL_API/blocks/tip/height" 2>/dev/null
}

fetch_price() {
    curl -s --max-time 5 "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=brl,usd" 2>/dev/null
}

fetch_difficulty() {
    curl -s --max-time 5 "$MEMPOOL_API/v1/difficulty-adjustment" 2>/dev/null
}

POOL_DATA=""
BLOCK_HEIGHT=""
BTC_PRICE_BRL=""
BTC_PRICE_USD=""
LAST_FETCH=0

while true; do
    NOW=$(date +%s)

    if [ $((NOW - LAST_FETCH)) -ge 60 ] || [ $LAST_FETCH -eq 0 ]; then
        POOL_DATA=$(fetch_pool)
        BLOCK_HEIGHT=$(fetch_network)
        PRICE_DATA=$(fetch_price)
        DIFF_DATA=$(fetch_difficulty)
        BTC_PRICE_BRL=$(echo "$PRICE_DATA" | grep -oP '"brl":\K[\d.]+' | head -1)
        BTC_PRICE_USD=$(echo "$PRICE_DATA" | grep -oP '"usd":\K[\d.]+' | head -1)
        DIFFICULTY=$(echo "$DIFF_DATA" | grep -oP '"difficulty":\K[\d.e+]+' | head -1)
        LAST_FETCH=$NOW
    fi

    HASHRATE=$(grep -oP '[\d.]+ [kMG]hash/s' "$LOG" 2>/dev/null | tail -1)
    SHARES=$(grep -c "accepted" "$LOG" 2>/dev/null || echo 0)
    REJECTED=$(grep -c "rejected" "$LOG" 2>/dev/null || echo 0)
    LAST=$(tail -1 "$LOG" 2>/dev/null | sed 's/\[.*\] //')
    UPTIME=$(ps -o etime= -p "$(pgrep minerd 2>/dev/null)" 2>/dev/null | tr -d ' ' || echo "nao rodando")

    TEMP=$(vcgencmd measure_temp 2>/dev/null | grep -oP '[\d.]+')
    CPU=$(top -bn1 | grep "Cpu(s)" | grep -oP '[\d.]+' | head -1)
    RAM=$(free -m | awk '/Mem:/ {printf "%.0f/%.0fMB (%.0f%%)", $3, $2, $3/$2*100}')
    FREQ=$(vcgencmd measure_clock arm 2>/dev/null | grep -oP '\d+' | awk '{printf "%.0f MHz", $1/1000000}')
    VOLTS=$(vcgencmd measure_volts core 2>/dev/null | grep -oP '[\d.]+')
    THROTTLE=$(vcgencmd get_throttled 2>/dev/null | grep -oP '0x\w+')

    POOL_HASHRATE=$(echo "$POOL_DATA" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    w=[x for x in d.get('workers',[]) if x.get('name')=='$WORKER']
    if w: print(w[0].get('hashRate',0))
    else: print(0)
except: print(0)
" 2>/dev/null)

    BEST_DIFF=$(echo "$POOL_DATA" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    w=[x for x in d.get('workers',[]) if x.get('name')=='$WORKER']
    if w: print(w[0].get('bestDifficulty','--'))
    else: print('--')
except: print('--')
" 2>/dev/null)

    BEST_GLOBAL=$(echo "$POOL_DATA" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print(round(d.get('bestDifficulty',0),2))
except: print('--')
" 2>/dev/null)

    WORKERS=$(echo "$POOL_DATA" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get('workersCount','--'))
except: print('--')
" 2>/dev/null)

    POOL_HR_FMT="--"
    if [ -n "$POOL_HASHRATE" ] && [ "$POOL_HASHRATE" -gt 0 ] 2>/dev/null; then
        POOL_HR_FMT=$(awk "BEGIN {printf \"%.2f MH/s\", $POOL_HASHRATE/1000000}")
    fi

    THROTTLE_MSG="OK"
    if [ "$THROTTLE" != "0x0" ] && [ -n "$THROTTLE" ]; then
        THROTTLE_MSG="ATENCAO: $THROTTLE"
    fi

    DIFF_FMT="--"
    if [ -n "$DIFFICULTY" ]; then
        DIFF_FMT=$(python3 -c "print(f'{float(\"$DIFFICULTY\")/1e12:.2f} T')" 2>/dev/null)
    fi

    # Limpa tela completamente antes de redesenhar
    clear
    echo "=================================================="
    printf "   RasPiMiner - Raspberry Pi 4   %s\n" "$(date '+%d/%m/%Y %H:%M:%S')"
    echo "=================================================="
    echo "  --- MINERADOR ---"
    printf "  Hashrate local : %-30s\n" "${HASHRATE:-aguardando...}"
    printf "  Hashrate pool  : %-30s\n" "${POOL_HR_FMT}"
    printf "  Shares aceitas : %-30s\n" "${SHARES}"
    printf "  Shares rejeit. : %-30s\n" "${REJECTED}"
    printf "  Best diff RPi4 : %-30s\n" "${BEST_DIFF:-aguardando...}"
    printf "  Best diff pool : %-30s\n" "${BEST_GLOBAL:-aguardando...}"
    printf "  Uptime minerd  : %-30s\n" "${UPTIME}"
    echo "--------------------------------------------------"
    echo "  --- POOL ---"
    printf "  Workers ativos : %-30s\n" "${WORKERS:-aguardando...}"
    echo "--------------------------------------------------"
    echo "  --- BITCOIN ---"
    printf "  Bloco atual    : %-30s\n" "${BLOCK_HEIGHT:-aguardando...}"
    printf "  Dificuldade    : %-30s\n" "${DIFF_FMT}"
    printf "  Preco BTC/BRL  : R\$ %-27s\n" "${BTC_PRICE_BRL:-aguardando...}"
    printf "  Preco BTC/USD  : US\$ %-26s\n" "${BTC_PRICE_USD:-aguardando...}"
    echo "--------------------------------------------------"
    echo "  --- RASPBERRY PI 4 ---"
    printf "  Temperatura    : %-30s\n" "${TEMP}C"
    printf "  CPU uso        : %-30s\n" "${CPU}%%"
    printf "  RAM            : %-30s\n" "${RAM}"
    printf "  Frequencia CPU : %-30s\n" "${FREQ}"
    printf "  Voltagem core  : %-30s\n" "${VOLTS}V"
    printf "  Throttle       : %-30s\n" "${THROTTLE_MSG}"
    echo "--------------------------------------------------"
    printf "  %.48s\n" "${LAST}"
    echo "=================================================="
    echo "  Dados externos atualizados a cada 60s | Ctrl+C para sair"

    sleep 5
done
