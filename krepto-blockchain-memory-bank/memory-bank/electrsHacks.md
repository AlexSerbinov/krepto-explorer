# Electrs Хаки для Krepto Blockchain - Повна Документація

## 🎯 Огляд Проблеми

**Основна проблема**: Electrs розроблений для Bitcoin blockchain і очікує стандартний Bitcoin Genesis блок. Krepto має власний унікальний Genesis блок, що викликає конфлікти.

### 🔗 Genesis блоки:
- **Bitcoin**: `000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f`
- **Krepto**: `3f5a49945b1be2da6541af9d90434c6cad4923d25141a5b77c4c064584b2865c`

## 🛠️ Хронологія Хаків та Підходів

### 1. Початкові Спроби (Конфігураційний підхід)

#### 1.1 Спроба Regtest
```bash
# Спробували запустити Electrs в regtest режимі
./target/release/electrs --conf /etc/electrs/config.toml --network regtest
```
**Результат**: ❌ Electrs очікував Bitcoin regtest Genesis, не Krepto

#### 1.2 Спроба Signet
```bash
# Перейшли на signet з custom magic bytes
./target/release/electrs --conf /etc/electrs/config.toml --signet-magic 4b524550
```
**Magic bytes пояснення**:
- `4b524550` = "KREP" в ASCII hex
- K=4b, R=52, E=45, P=50

**Результат**: ⚠️ Magic bytes розпізналися, але Genesis блок все ще проблема

### 2. Конфігураційні Файли

#### 2.1 /etc/electrs/config.toml
```toml
network = "signet"                     # Використовуємо signet замість regtest
daemon_rpc_addr = "127.0.0.1:12347"   # Krepto RPC порт
daemon_p2p_addr = "127.0.0.1:12345"   # Krepto P2P порт  
electrum_rpc_addr = "127.0.0.1:50001" # Electrum Protocol порт
auth = "kreptouser:krepto2024secure!"  # Креденціали Krepto ноди
db_path = "/var/lib/electrs-krepto/signet"  # Відокремлена база даних
```

#### 2.2 Спроби з різними мережами
```bash
# Перепробували всі можливі варіанти:
--network bitcoin      # ❌ Очікує Bitcoin mainnet
--network testnet      # ❌ Очікує Bitcoin testnet  
--network regtest      # ❌ Очікує Bitcoin regtest
--network signet       # ⚠️ Працює з magic bytes, але Genesis проблема
```

## 🚨 Основні Помилки До Хаків

### 2.1 "missing prev_blockhash" Error
```
Error: missing prev_blockhash in p2p.rs:84
```
**Причина**: Electrs шукає Bitcoin Genesis блок у Krepto блокчейні

### 2.2 "missing genesis header" Panic  
```
Panic: missing genesis header {hash} in chain.rs:70
```
**Причина**: Electrs не може знайти очікуваний Genesis блок у своїй базі даних

## 🔧 Code Patching Рішення (KREPTO HACK)

### 3.1 Знаходження файлів для патчинга
```bash
# Знайшли файли в cargo registry:
find /root/.cargo -name "p2p.rs" -path "*electrs*"
find /root/.cargo -name "chain.rs" -path "*electrs*" 

# Шляхи:
/root/.cargo/registry/src/index.crates.io-6f17d22bba15001f/electrs-0.10.9/src/new_index/p2p.rs
/root/.cargo/registry/src/index.crates.io-6f17d22bba15001f/electrs-0.10.9/src/new_index/chain.rs
```

### 3.2 Патч #1 - p2p.rs (лінія 84)

#### Оригінальний код:
```rust
match self.chain.get_block_height(prev_blockhash) {
    Some(height) => height..end,
    None => return Err("missing prev_blockhash".into()),  // ❌ Крешилося тут
}
```

#### KREPTO HACK:
```rust
match self.chain.get_block_height(prev_blockhash) {
    Some(height) => height..end,
    None => { 
        warn!("KREPTO HACK: ignoring missing genesis {}", prev_blockhash); 
        0..end  // ✅ Починаємо з блоку 0 замість краху
    }
}
```

**Команда для застосування**:
```bash
sed -i '84s/None => return Err("missing prev_blockhash".into()),/None => { warn!("KREPTO HACK: ignoring missing genesis {}", prev_blockhash); 0..end }/' p2p.rs
```

### 3.3 Патч #2 - chain.rs (лінія 70)

#### Оригінальний код:
```rust
let header = match self.headers.header_by_blockhash(blockhash) {
    Some(header) => header,
    None => panic!("missing genesis header {}", blockhash),  // ❌ Панікував тут
};
```

#### KREPTO HACK:
```rust  
let header = match self.headers.header_by_blockhash(blockhash) {
    Some(header) => header,
    None => { 
        warn!("KREPTO HACK: missing genesis header {}, breaking loop", blockhash); 
        break;  // ⚠️ Виходимо з циклу замість паніки
    }
};
```

**Команда для застосування**:
```bash
sed -i '70s/None => panic!("missing genesis header {}", blockhash),/None => { warn!("KREPTO HACK: missing genesis header {}, breaking loop", blockhash); break; }/' chain.rs
```

## 🔄 Процедура Застосування Хаків

### 4.1 Backup оригінальних файлів
```bash
cp /root/.cargo/registry/src/.../p2p.rs /root/.cargo/registry/src/.../p2p.rs.backup
cp /root/.cargo/registry/src/.../chain.rs /root/.cargo/registry/src/.../chain.rs.backup
```

### 4.2 Застосування патчів
```bash
cd /root/.cargo/registry/src/index.crates.io-6f17d22bba15001f/electrs-0.10.9/src/new_index/

# Патч 1 - p2p.rs
sed -i '84s/None => return Err("missing prev_blockhash".into()),/None => { warn!("KREPTO HACK: ignoring missing genesis {}", prev_blockhash); 0..end }/' p2p.rs

# Патч 2 - chain.rs  
sed -i '70s/None => panic!("missing genesis header {}", blockhash),/None => { warn!("KREPTO HACK: missing genesis header {}, breaking loop", blockhash); break; }/' chain.rs
```

### 4.3 Перекомпіляція
```bash
cd /opt/electrs
cargo build --release
# Час компіляції: ~1-2 хвилини
```

## 📊 Результати Хаків

### ✅ Що працює:
- Electrs запускається без крешів
- Індексація всіх блоків крім Genesis (блоків 1-26483+)
- Electrum Protocol API відповідає
- Address lookups працюють
- BTC RPC Explorer показує баланси

### ⚠️ Побічні ефекти:
- **Блок 0 недоступний**: "Transaction details unavailable due to blockchain pruning block 0"
- **Genesis транзакції не індексуються**: Перша coinbase транзакція пропущена

### 🔍 Логи з хаками:
```log
WARN electrs: KREPTO HACK: ignoring missing genesis 3f5a49945b1be2da6541af9d90434c6cad4923d25141a5b77c4c064584b2865c
WARN electrs: KREPTO HACK: missing genesis header 3f5a49945b1be2da6541af9d90434c6cad4923d25141a5b77c4c064584b2865c, breaking loop
```

## 🚨 Проблема з Блоком 0 - Детальний Аналіз

### Причина проблеми:
**chain.rs hack використовує `break`** замість `continue`:
```rust
None => { 
    warn!("KREPTO HACK: missing genesis header {}, breaking loop", blockhash); 
    break;  // ❌ Зупиняє весь цикл індексації
}
```

### Що відбувається:
1. Electrs починає індексацію з блоку 0
2. Не знаходить Genesis header у своїй базі (бо очікує Bitcoin Genesis)
3. Виконує наш hack з `break`
4. **Повністю виходить з циклу індексації**
5. Genesis блок **НЕ додається до бази даних**
6. Explorer не може показати деталі блоку 0

## 🔧 Можливі Рішення Проблеми з Блоком 0

### Рішення 1: Зміна break на continue
```rust
None => { 
    warn!("KREPTO HACK: missing genesis header {}, continuing", blockhash); 
    continue;  // ✅ Пропускаємо Genesis, але продовжуємо індексацію
}
```

### Рішення 2: Додавання фейкового Genesis header
```rust
None => { 
    warn!("KREPTO HACK: creating fake genesis header {}", blockhash);
    // Створити мінімальний header з Krepto Genesis даними
    let fake_header = create_krepto_genesis_header(blockhash);
    fake_header
}
```

### Рішення 3: Пропуск блоку 0 в запитах
```rust
// В API layer додати перевірку:
if block_height == 0 {
    return get_genesis_from_krepto_node();
}
```

## 🔄 Процедура Виправлення (майбутня)

### При заміні Genesis блоку:
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
5. **Оновити хаки Electrs** (при необхідності)
6. **Перекомпілювати Electrs**
7. **Перезапустити сервіси**

## 📁 Де Зберігаються Хаки

### Локація файлів:
- **Оригінали**: `/root/.cargo/registry/src/.../electrs-0.10.9/src/new_index/`
- **Backups**: `*.backup` файли в тій же директорії
- **Compiled binary**: `/opt/electrs/target/release/electrs`

### Конфігурація:
- **Electrs config**: `/etc/electrs/config.toml`
- **База даних**: `/var/lib/electrs-krepto/signet/`
- **Логи**: `/var/log/electrs-krepto-genesis-fix.log`

## 🎯 Висновки

### Успіхи:
- ✅ **Electrs працює** з Krepto blockchain
- ✅ **26,483+ блоків** проіндексовано
- ✅ **Address API** функціонує
- ✅ **BTC RPC Explorer** показує баланси

### Обмеження:
- ⚠️ **Блок 0 недоступний** через break в chain.rs
- ⚠️ **Genesis транзакції** не індексуються
- ⚠️ **Хаки залежать від версії Electrs** (0.10.9)

### Рекомендації:
1. **Короткострокове**: Використовувати поточну систему (працює для 99.99% блоків)
2. **Довгострокове**: Розробити proper Genesis handling в Electrs fork
3. **При Genesis заміні**: Переробити хаки з врахуванням нового Genesis блоку

**Статус**: ✅ Задокументовано повністю  
**Складність відтворення**: Середня (потребує Rust знань)  
**Ефективність**: 99.99% (всі блоки крім Genesis) 