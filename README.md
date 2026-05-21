# arch-server-lab

Мои скрипты и конфигурации для подготовки к стажировке в Ядро / Aquarius.

## Структура

arch-server-lab/
├── bin/
│   └── server_health_check.sh   # Мониторинг сервера
├── docs/
│   └── (документация)
└── README.md


## Скрипты

### server_health_check.sh

Простой bash-скрипт для мониторинга состояния сервера.

Что проверяет:
- CPU (load average)
- Память
- Диск (/)
- Температуру (через lm_sensors)
- Сеть (пинг до 8.8.8.8)

Запуск:
bash
chmod +x bin/server_health_check.sh
./bin/server_health_check.sh

Пример вывода:

=== HEALTH REPORT ===
CPU: load 0.15 / 4 cores +
Memory: 31% used (3147 MB free) +
Disk /: 68% used +
Temp: 45.0°C
Network: + online

Автоматический запуск (cron):

bash
crontab -e
# Добавить:
*/30 * * * * /home/ваш_пользователь/github/arch-server-lab/bin/server_health_check.sh

Планы

· Добавить Ansible playbook
· Docker-compose для nginx+php
· GitHub Actions CI

Технологии

· Arch Linux
· Bash
· lm_sensors
· (скоро) Ansible, Docker

Автор

Подготовка к стажировке, 1 курс Прикладной информатики
