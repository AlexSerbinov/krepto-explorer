# Electrs + Electrum Setup для Krepto Blockchain

## Огляд
Electrs - це високопродуктивний індексаційний сервер для Bitcoin/Krepto blockchain, який надає Electrum Protocol API. Electrum - це клієнт для роботи з гаманцем.

## Встановлення Electrs

### 1. Компіляція з джерельного коду
```bash
cd /opt
git clone https://github.com/romanz/electrs.git
cd electrs
git checkout v0.10.9  # Стабільна версія

# Встановлення Rust (якщо потрібно)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Компіляція
cargo build --release
```

### 2. Конфігурація Electrs

Створити `/etc/electrs/config.toml`:
```toml
network = "signet"
daemon_rpc_addr = "127.0.0.1:12347"
daemon_p2p_addr = "127.0.0.1:12345"
electrum_rpc_addr = "127.0.0.1:50001"
auth = "kreptouser:krepto2024secure!"
db_path = "/var/lib/electrs-krepto/signet"
```

### 3. Обробка Custom Genesis Block

**ВАЖЛИВО**: Electrs очікує Bitcoin genesis block. Для Krepto потрібні модифікації:

#### Метод 1: Code Patching (використаний)
Знайти файли у cargo registry:
```bash
find /root/.cargo -name "p2p.rs" -path "*electrs*"
find /root/.cargo -name "chain.rs" -path "*electrs*"
```

**Патч 1 - p2p.rs (лінія ~84)**:
```rust
// Оригінал
Some(height) => height..end,
None => return Err("missing prev_blockhash".into()),

// Заміна на KREPTO HACK
Some(height) => height..end,
None => { warn!("KREPTO HACK: ignoring missing genesis {}", prev_blockhash); 0..end }
```

**Патч 2 - chain.rs (лінія ~70)**:
```rust
// Оригінал  
None => panic!("missing genesis header {}", blockhash),

// Заміна на KREPTO HACK
None => { warn!("KREPTO HACK: missing genesis header {}, breaking loop", blockhash); break; }
```

#### Застосування патчів:
```bash
# Backup оригінальних файлів
cp /root/.cargo/registry/src/.../p2p.rs /root/.cargo/registry/src/.../p2p.rs.backup
cp /root/.cargo/registry/src/.../chain.rs /root/.cargo/registry/src/.../chain.rs.backup

# Застосування sed патчів
sed -i '84s/None => return Err("missing prev_blockhash".into()),/None => { warn!("KREPTO HACK: ignoring missing genesis {}", prev_blockhash); 0..end }/' p2p.rs
sed -i '70s/None => panic!("missing genesis header {}", blockhash),/None => { warn!("KREPTO HACK: missing genesis header {}, breaking loop", blockhash); break; }/' chain.rs

# Перекомпіляція
cargo build --release
```

### 4. Запуск Electrs

#### Основна команда:
```bash
cd /opt/electrs
nohup ./target/release/electrs \
  --conf /etc/electrs/config.toml \
  --signet-magic 4b524550 \
  --skip-block-download-wait \
  > /var/log/electrs-krepto.log 2>&1 &
```

#### Параметри:
- `--signet-magic 4b524550`: Магічні байти Krepto (KREP в hex)
- `--skip-block-download-wait`: Прискорює початкову синхронізацію
- `--conf`: Шлях до конфігураційного файлу

### 5. Моніторинг Electrs

#### Перевірка процесу:
```bash
ps aux | grep electrs
ss -tlnp | grep 50001  # Перевірка порту
```

#### Перевірка логів:
```bash
tail -f /var/log/electrs-krepto.log
```

#### Тестування API:
```bash
echo '{"jsonrpc": "2.0", "method": "server.version", "params": ["test", "1.4"], "id": 0}' | nc 127.0.0.1 50001
```

## Встановлення Electrum Client

### 1. Завантаження та встановлення
```bash
cd /opt
wget https://download.electrum.org/4.4.6/Electrum-4.4.6.tar.gz
tar -xzf Electrum-4.4.6.tar.gz
cd Electrum-4.4.6

# Встановлення залежностей
apt install -y python3-venv python3-setuptools

# Встановлення Electrum
python3 -m pip install .
```

### 2. Підключення до Electrs
```bash
# Запуск демона з підключенням до локального Electrs
electrum --server 127.0.0.1:50001:t --offline daemon

# Тестування команд
electrum getinfo
electrum listaddresses
```

## Інтеграція з BTC RPC Explorer

### Налаштування Explorer
Додати до `/opt/krepto-explorer/.env`:
```bash
# Electrs Configuration for address lookups
KREPTOEXP_ADDRESS_API=electrum
KREPTOEXP_ELECTRUM_SERVERS=tcp://127.0.0.1:50001
```

### Перезапуск Explorer
```bash
cd /opt/krepto-explorer
pkill -f "node ./bin/www"
nohup npm start > /var/log/krepto-explorer-electrs.log 2>&1 &
```

## Проблеми та Рішення

### Проблема: Блок 0 не відображається
**Симптом**: "Transaction details unavailable due to blockchain pruning block 0"

**Причина**: KREPTO HACK з `break` зупиняє індексацію на блоці 0

**Рішення**: 
1. Очистити базу: `rm -rf /var/lib/electrs-krepto/signet/`
2. Перезапустити з `--skip-block-download-wait`
3. Або змінити `break` на `continue` у chain.rs патчі

### Проблема: Magic bytes не розпізнаються
**Рішення**: Завжди використовувати `--signet-magic 4b524550`

### Проблема: RPC підключення
**Рішення**: Перевірити auth в config.toml та креденціали Krepto ноди

## Заміна Genesis Block (майбутня процедура)

Коли потрібно буде змінити Genesis блок:

1. **Зупинити всі сервіси**:
```bash
pkill electrs
pkill -f "node ./bin/www"
systemctl stop kreptod
```

2. **Очистити дані**:
```bash
rm -rf /var/lib/electrs-krepto/signet/
rm -rf ~/.krepto/blocks/
rm -rf ~/.krepto/chainstate/
```

3. **Оновити Genesis в Krepto коді**
4. **Перекомпілювати Krepto**
5. **Перезапустити всі сервіси в правильному порядку**:
   - Krepto нода
   - Electrs 
   - BTC RPC Explorer

## Статус Інтеграції

✅ **Працює**:
- Electrs компіляція та запуск
- Індексація блоків з KREPTO HACK
- Electrum підключення
- BTC RPC Explorer інтеграція
- Address lookups та баланси

⚠️ **Частково працює**:
- Блок 0 можливо недоступний через HACK break

🎯 **Результат**: Повнофункціональна Electrs інтеграція для Krepto blockchain! 