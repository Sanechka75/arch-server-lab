#!/usr/bin/env bash

# server_health_check.sh
# Мониторинг сервера без bc и с fallback-ами

# Лог в домашней папке (не нужно sudo)
LOG_FILE="/home/sashka/server_health.log"

# Функция логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Проверка CPU (load average)
CPU_LOAD=$(uptime | awk -F 'load average:' '{print $2}' | cut -d, -f1 | xargs)
CPU_CORES=$(nproc)

# Сравнение без bc (используем awk)
HIGH_LOAD=$(awk "BEGIN {print ($CPU_LOAD > $CPU_CORES) ? 1 : 0}")

# Проверка памяти
MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
MEM_AVAIL=$(free -m | awk '/^Mem:/{print $7}')
MEM_USED_PERCENT=$(( (MEM_TOTAL - MEM_AVAIL) * 100 / MEM_TOTAL ))

# Проверка диска (корневой раздел)
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

# Проверка температуры (если есть sensors)
if command -v sensors &> /dev/null; then
    TEMP=$(sensors 2>/dev/null | grep -i "Package id 0" | awk '{print $4}' | sed 's/+//' | sed 's/°C//')
    if [ -z "$TEMP" ]; then
        TEMP=$(sensors 2>/dev/null | grep -i "Core 0" | awk '{print $3}' | sed 's/+//' | sed 's/°C//')
    fi
    [ -z "$TEMP" ] && TEMP="N/A"
else
    TEMP="N/A (install lm_sensors)"
fi

# Проверка сети (пинг до 8.8.8.8)
ping -c 1 -W 1 8.8.8.8 &> /dev/null
NETWORK_STATUS=$?

# Формирование отчета
CPU_STATUS="+"
if [ "$HIGH_LOAD" -eq 1 ]; then
    CPU_STATUS=" - HIGH"
fi

MEM_STATUS="+"
if [ $MEM_USED_PERCENT -gt 90 ]; then
    MEM_STATUS=" - LOW MEMORY"
fi

DISK_STATUS="+"
if [ ${DISK_USAGE} -gt 85 ]; then
    DISK_STATUS=" - LOW SPACE"
fi

NETWORK_STATUS_TEXT=" + online"
if [ $NETWORK_STATUS -ne 0 ]; then
    NETWORK_STATUS_TEXT=" - offline"
fi

REPORT="=== HEALTH REPORT ===
CPU: load $CPU_LOAD / $CPU_CORES cores $CPU_STATUS
Memory: $MEM_USED_PERCENT% used ($MEM_AVAIL MB free) $MEM_STATUS
Disk /: $DISK_USAGE% used $DISK_STATUS
Temp: $TEMP
Network: $NETWORK_STATUS_TEXT
"

# Логируем
log "$REPORT"

# Уведомление при проблемах
if [ "$HIGH_LOAD" -eq 1 ] || [ $MEM_USED_PERCENT -gt 90 ] || [ ${DISK_USAGE} -gt 85 ] || [ $NETWORK_STATUS -ne 0 ]; then
    log " - PROBLEMS DETECTED!"
    # Раскомментить если нужны email оповещения:
    # echo "$REPORT" | mail -s "Server Alert" your@email.com
fi

# Красивый вывод в терминал
# echo "$REPORT"
