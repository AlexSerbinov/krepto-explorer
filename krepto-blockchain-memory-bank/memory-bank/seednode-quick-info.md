# Krepto Seed Node - Швидка Довідка

## 🎯 МЕТА
Розгорнути Krepto seed ноду з майнінгом на VPS сервері для:
- Постійного підключення нових користувачів
- Розподіленого майнінгу (сервер ↔ локальний комп'ютер)
- Стабільності мережі Krepto

## 📋 КЛЮЧОВА ІНФОРМАЦІЯ

### Вимоги до Сервера
- **CPU**: 2+ ядра
- **RAM**: 4GB+ (рекомендовано 8GB)
- **Storage**: 50GB+ SSD
- **OS**: Ubuntu 20.04+ або CentOS 8+
- **Network**: Статичний IP

### Порти
- **P2P**: 12345
- **RPC**: 12347

### Основні Компоненти
1. **Krepto Daemon** (`kryptod`) - основна нода
2. **Mining Service** (`krepto-mining`) - автоматичний майнінг
3. **Monitor Script** - моніторинг стану
4. **Security** - firewall, fail2ban

## 🚀 ШВИДКИЙ СТАРТ

### Після Розгортання на Сервері
```bash
# Перевірити статус
sudo systemctl status krepto krepto-mining

# Моніторинг майнінгу
tail -f /home/krepto/mining.log

# Перевірити blockchain
krepto-cli -datadir=/home/krepto/.krepto getblockchaininfo
```

### На Локальному Комп'ютері
```bash
# Підключитися до seed ноди (замінити IP)
./src/krepto-cli -datadir=/Users/serbinov/.krepto addnode "SERVER_IP:12345" "add"

# Перевірити підключення
./src/krepto-cli -datadir=/Users/serbinov/.krepto getpeerinfo

# Оновити chainparams.cpp
# Додати в src/kernel/chainparams.cpp:
# vSeeds.emplace_back("SERVER_IP:12345");
```

## 📊 ОЧІКУВАНИЙ РЕЗУЛЬТАТ

### Розподілений Майнінг
- Сервер майнить блоки автоматично з рандомізацією
- Локальний комп'ютер майнить через GUI
- Блоки майняться по черзі між нодами
- Справедливий розподіл роботи

### Мережева Стабільність
- Seed нода працює 24/7
- Нові користувачі автоматично підключаються
- Мережа стає децентралізованою
- Захист від відключення окремих нод

## 📁 ВАЖЛИВІ ФАЙЛИ

### На Сервері
- `/home/krepto/.krepto/krepto.conf` - конфігурація
- `/home/krepto/.krepto/rpc_credentials` - паролі та адреси
- `/home/krepto/mining_script.sh` - скрипт майнінгу
- `/home/krepto/mining.log` - логи майнінгу
- `/home/krepto/IMPORTANT_INFO.txt` - ключова інформація

### Локально
- `memory-bank/seednode-deployment-guide.md` - повна інструкція
- `src/kernel/chainparams.cpp` - потребує оновлення seed нод

## ⚡ СТАТУС
- ✅ **Інструкція**: Повністю готова
- 📋 **Розгортання**: Готово для передачі іншій LLM
- 🎯 **Мета**: Розподілений майнінг та стабільність мережі
- 🚀 **Результат**: Krepto стане повністю децентралізованим

**ГОТОВО ДО РОЗГОРТАННЯ!** 🎉 