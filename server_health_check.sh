# !/usr/bin/env bash

LOG_FILE="/home/sashka/server_health.log"

log_to_file(){
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# uptime даст фулл строку (время, пользователи, load average 0.12, 0.06, 0.05)
# awk -F 'load average:' '{print $2}' - awk вырезает все после load average ( 0.12, 0.06, 0.05 )
# cut -d, -f1 - оставляет только первую часть перед запятой ( 0.12 )
# xargs - убирает лишние пробелы
CPU_LOAD=$(uptime | awk -F 'load average:' '{print $2}' | cut -d, -f1 | xargs)

# nproc (number of processors) - покажет сколько ядер у процессора и запишет в переменную
CPU_CORES=$(nproc)

# awk умеет работать с дробными, bash - нет (поэтому используем awk)
# BEGIN - выполни код сразу, без чтения входных данных
# ($CPU_LOAD > $CPU_CORES) ? 1 : 0 это вообще if else:
# (условие) ? истина, иначе ложь
# получается если нагрузка больше чем кол-во ядер, то в переменной будет 1, если все норм то 0
HIGH_LOAD=$(awk "BEGIN {print ($CPU_LOAD > $CPU_CORES) ? 1 : 0}")

# CPU_STATUS по умолчанию выдает + NORMAL (при 0 в $HIGH_LOAD)
# но если $HIGH_LOAD -eq 1 ($HIGH_LOAD == 1(-eq == equal)) то (&&) выполнить некст условие
# можно записать и в несколько строк (ниже)
# CPU_STATUS="+ NORMAL"
# if [ $HIGH_LOAD -eq 1 ]; then
    # CPU_STATUS="- HIGH"
# fi
CPU_STATUS="+ NORMAL"; [ $HIGH_LOAD -eq 1 ] && CPU_STATUS="- HIGH"

# получаем общую память в мегабайтах
# free - команда, показывающая информацию о памяти
# -m (me bibytes) - выводит цифры в мегабайтах
# /.../ - условие, ищем строку, подходящую под шаблон внутри
# ^ - якорь (начало строки)
# Mem: - точный текст по которому искать
MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')

# аналогично как и выше, только берем 7 поле
MEM_AVAIL=$(free -m | awk '/^Mem:/{print $7}')

# (( ... )) - это арифметическое вычисление в bash, только с целыми числами
# MEM_T - MEM_A = занятая память
# занятая память * 100 и / на MEM_T = процентов занято
MEM_USED_PERCENT=$(( (MEM_TOTAL - MEM_AVAIL) * 100 / MEM_TOTAL ))

# тут проверяем что забито меньше 80% памяти
MEM_STATUS="+ A LOT OF MEMORY"
if [ $MEM_USED_PERCENT -gt 80 ]; then
    MEM_STATUS="- LOW MEMORY"
fi

# df (Disc Free) -h (human readable)/ - выводит корневой (/) диск и инфу про память 
# NR==2 (Number of Record) - берем вторую строку, заголовок скипаем
# {print %5} - печатаем 5 поле
# sed (Stream Editor) - редактирует текст 
# s/.../.../ - команда замены (substitute)
# мы ищем знак %, следовательно s/%// (ищем % и меняем на знак между //, на пустоту)
# ps <можно было заменить например на ! (sed 's/%/!/')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}'| sed 's/%//')

# проверяем что на диске забито меньше 85% памяти 
DISC_STATUS="+ A LOT OF SPACE"
if [ $DISK_USAGE -gt 85 ]; then
    DISC_USAGE="- LOW SPACE"
fi

# значение по умолчанию, если не удалось получить темпу (Not Available)
TEMP="N/A"

# проверяем, существует ли команда sensors (command -v sensors)
# &> /dev/null - перенаправляем весь вывод вникуда (чтобы ничего не вывело на экран)
if command -v sensors &> /dev/null; then

    # пробуем найти температуру процессора (Package id 0)
    # 2>dev/null - перенаправляем ошибки вникуда
    # grep -i "Package id 0" - grep (поиск текста) -i (игнор регистра)
    TEMP=$(sensors 2>/dev/null | grep -i "Package id 0" | awk '{print $4}' | sed 's/+//; s/°C//')

    # если вдруг не нашли, пробуем другой вариант (Core 0)
    # -z - оператор (zero length) проверяет, пустая ли строка
    # && - если $TEMP пустая (истина) то выполняем условие справа
    [ -z "$TEMP" ] && TEMP=$(sensors 2>/dev/null | grep -i "Core 0" | awk '{print $3}' | sed 's/+//; s/°C//')
fi

# ping - команда для проверки доступности хоста
# -c 1 - отправить 1 пакет (count)
# -W 1 - ждать ответ 1 секунду (timeout)
# 8.8.8.8 адрес Google DNS (всегда доступен, имба)
ping -c 1 -W 1 8.8.8.8 &> /dev/null

# так сохраняется код возврата (где 0 - успех, другое - ошибка)
NETWORK_OK=$?
 
NETWORK_STATUS="+ online"

# -ne - не равно (Not Equal)
if [ $NETWORK_OK -ne 0 ]; then
    NETWORK_STATUS="- offline"
fi

# некий ответ
# в переменную REPORT пихаем много текста и найденных ранее значений
REPORT="=== HEALTH REPORT ===
CPU: load $CPU_LOAD / $CPU_CORES cores $CPU_STATUS
Memory: $MEM_USED_PERCENT% used ($MEM_AVAIL MB free) $MEM_STATUS
Disk /: $DISK_USAGE% used $DISC_STATUS
Temp: $TEMP
Network: $NETWORK_STATUS
"

# echo выводит на экран
echo "$REPORT"

# функция log_to_file вносит в лог (см строка 5)
log_to_file "$REPORT"

# если найдется хоть одна проблема - напишем предупреждение в лог
# || - логический оператор или (или то не работает или то или то)
if [ "$HIGH_LOAD" -eq 1 ] || [ $MEM_USED_PERCENT -gt 80 ] || [ $DISK_USAGE -gt 85 ] || [ $NETWORK_OK -ne 0 ]; then
    log_to_file="PROBLEMS BROOOOOOO"
fi

# это было здраво, едем дальше)
