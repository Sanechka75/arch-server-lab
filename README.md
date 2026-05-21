# arch-server-lab

Мониторинг и автоматизация сервера на Arch Linux / Ubuntu.

[![made-with-bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff)]()

## О проекте

Этот репозиторий — результат подготовки к стажировке в **Ядро** / **Aquarius**.  
Здесь я собираю скрипты и конфиги для серверного администрирования.  

Уже реализовано:  
- Bash-скрипт мониторинга сервера  
- Логирование состояния (CPU, RAM, диск, сеть, температура)  
- Автоматический запуск через cron  

В планах:  
- Ansible playbook для установки nginx  
- Docker-compose (nginx + php + postgres)  
- GitHub Actions CI для проверки скриптов  

## Быстрый старт

git clone https://github.com/Sanechka75/arch-server-lab.git  
cd arch-server-lab  
chmod +x server_health_check.sh  
./server_health_check.sh  
Скрипт мониторинга  

Что проверяет:

· Загрузку CPU  
· Использование памяти  
· Занятость диска (/)  
· Температуру процессора (через lm_sensors)  
· Сеть (пинг до 8.8.8.8)  

Пример вывода:

=== HEALTH REPORT ===  
CPU: load 0.15 / 4 cores +  
Memory: 31% used (3147 MB free) +  
Disk /: 68% used +  
Temp: 45.0°C  
Network: + online  

# Добавить строку (запуск каждые 30 минут):
*/30 * * * * /home/sashka/MyFiles/GitProjects/arch-server-lab/server_health_check.sh   
Логи пишутся в ~/server_health.log  
Автоматический запуск (cron)   

crontab -e  

Просмотр в реальном времени:  

tail -f ~/server_health.log  
Технологии  

Технология Назначение  
Arch Linux Основная ОС  
Bash Скрипты  
lm_sensors Датчики температуры  
cron Планировщик задач  
Git/GitHub Версионирование  

**Автор**

Студент 1 курса, Прикладная информатика.  
Подготовка к стажировке в Ядро / Aquarius.  

GitHub: Sanechka75  
