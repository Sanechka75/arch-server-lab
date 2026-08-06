# !/usr/bin/bash
LOG_FILE="/home/sashka/LogFiles/disk_usage.log"

log_to_file(){
    echo "$1" >> "$LOG_FILE"
}

dates=$(date '+%Y-%m-%d %H:%M:%S')
disc_usage=$(df -h / | awk 'NR==2 {print $5}'| sed 's/%//')

REPORT="
Дата - $dates
Использование диска - $disc_usage%"

log_to_file "$REPORT"

echo "$REPORT"
