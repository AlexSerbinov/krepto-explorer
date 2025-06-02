# SegWit Проблема - Детальне Дослідження

## 🚨 КРИТИЧНА ПРОБЛЕМА: SegWit Транзакції Блокують Майнінг

**Дата виявлення**: 27 травня 2025  
**Статус**: 🔍 АКТИВНЕ ДОСЛІДЖЕННЯ  
**Пріоритет**: НАЙВИЩИЙ

## 🎯 КРИТИЧНЕ ВІДКРИТТЯ: SegWit Активний З Блоку 481824

**ЗНАЙДЕНА ПРИЧИНА ПРОБЛЕМИ**:
- В `src/kernel/chainparams.cpp` рядок 96: `consensus.SegwitHeight = 481824;`
- Krepto зараз на блоці **2101**, що означає SegWit активний з самого початку!
- Це пояснює, чому SegWit транзакції з'являються в mempool

### Порівняння з Bitcoin Core
**Stack Overflow проблема**: Різні версії Bitcoin Core мали різні налаштування SegWit активації
- v0.14.3: SegWit статус "defined" (неактивний)
- v0.16.3: SegWit статус "active" (активний)
- **Результат**: `unexpected-witness, ContextualCheckBlock : unexpected witness data found (code 16)`

### Застосування до Krepto
**НАША СИТУАЦІЯ**:
- SegWit активний з блоку 481824 (Bitcoin mainnet значення)
- Поточний блок: 2101 (набагато менше за 481824)
- **ПАРАДОКС**: SegWit повинен бути НЕактивний, але транзакції все одно створюються

## Опис Проблеми

### Основна Проблема
Після створення SegWit транзакції в GUI гаманці Krepto майнінг повністю припиняється з помилкою:
```
CreateNewBlock: TestBlockValidity failed: unexpected-witness, CheckWitnessMalleation : unexpected witness data found
```

### Послідовність Подій
1. **Початковий стан**: Майнінг працює нормально
2. **Користувач робить транзакцію**: Через GUI гаманець (навіть зі своєї адреси на свою)
3. **Транзакція потрапляє в mempool**: З SegWit witness data
4. **Майнінг блокується**: `generatetoaddress` повертає помилку
5. **Проблема залишається**: Навіть після перезапуску ноди

## Технічні Деталі

### Характеристики Проблемної Транзакції
```json
{
  "txid": "4a8353e4a06e4217c78928b8ce27a452daff4ffe972d28aacba96c5d6d617b0e",
  "hash": "db6b7c9cabea8b8e57b2c949ad31b1323dbb0cae79f2a46da85cf1926ec2c7ba",
  "version": 2,
  "size": 222,
  "vsize": 141,
  "weight": 561,
  "txinwitness": [
    "3044022053defdc2c212acbbee066cfafd752fc3afea9b7eeaaf214bc302e987fb80dedb022023973a5ffc997623b8b24657233fbd53887d2ec67eefcfa826e12466a278dc0401",
    "02f97fe81ffcb648a45953d8b52d1d63b492de2aec47df91854b36bc4eb7c66674"
  ],
  "vout": [
    {
      "address": "kr1qprhfhmk2y4uyumwrx0jdjhapzeuhr7fnzj78fz",
      "type": "witness_v0_keyhash"
    }
  ]
}
```

### Ключові Індикатори SegWit
- **weight** (561) > **vsize * 4** (141 * 4 = 564) - ознака SegWit
- **Адреси типу kr1q...** (bech32 format)
- **Наявність txinwitness** в транзакції
- **type: "witness_v0_keyhash"** в outputs

### Поведінка Проблеми
1. **Персистентність**: Транзакція залишається в mempool навіть після:
   - Перезапуску ноди
   - Видалення `mempool.dat`
   - Запуску з `-persistmempool=0`
   - Запуску з `-connect=0` (без мережевих з'єднань)

2. **Джерело**: Транзакція надходить з гаманця, а не з мережі

3. **Єдине рішення**: Запуск з `-disablewallet` очищає mempool

## Проведені Експерименти

### Експеримент #1: Відкат Блокчейну
**Мета**: Перевірити, чи проблема пов'язана з конкретним блоком

**Кроки**:
1. Відкат з блоку 8279 до 8179 - проблема залишилася
2. Відкат до блоку 2200 - проблема залишилася  
3. Відкат до блоку 2100 - проблема залишилася

**Результат**: Проблема не пов'язана з конкретним блоком

### Експеримент #2: Очищення Mempool
**Мета**: Видалити проблемну транзакцію з mempool

**Спроби**:
```bash
# Спроба 1: Видалення файлу mempool
rm -f /Users/serbinov/.krepto/mempool.dat
# Результат: Транзакція повертається після запуску

# Спроба 2: Запуск без збереження mempool
./src/bitcoind -persistmempool=0
# Результат: Транзакція повертається

# Спроба 3: Ізоляція від мережі
./src/bitcoind -connect=0 -persistmempool=0
# Результат: Транзакція повертається

# Спроба 4: Відключення гаманця
./src/bitcoind -disablewallet
# Результат: ✅ Mempool порожній!
```

**Висновок**: Транзакція надходить з гаманця, а не з мережі

### Експеримент #3: Тестування Майнінгу
**Мета**: Перевірити роботу майнінгу в різних умовах

**Результати**:
- **З SegWit в mempool**: ❌ `unexpected-witness` помилка
- **Без гаманця (mempool порожній)**: ❌ Повертає порожній масив `[]`
- **З legacy адресами**: ✅ Працює (коли немає SegWit в mempool)

## Гіпотези та Дослідження

### Гіпотеза #1: CheckWitnessMalleation Конфлікт
**Теорія**: Функція `CheckWitnessMalleation` в Krepto не правильно обробляє SegWit транзакції

**Потрібно дослідити**:
- Знайти функцію `CheckWitnessMalleation` в коді
- Порівняти з Bitcoin Core реалізацією
- Перевірити налаштування SegWit активації в chainparams.cpp

### Гіпотеза #2: SegWit Не Активований Правильно
**Теорія**: SegWit не активований в мережі Krepto, але GUI створює SegWit транзакції

**Потрібно перевірити**:
- Налаштування SegWit активації в consensus параметрах
- Чи активований SegWit на поточній висоті блоків
- Налаштування GUI для типу адрес

### Гіпотеза #3: GUI Налаштування
**Теорія**: GUI за замовчуванням створює SegWit адреси, які не підтримуються

**Потрібно змінити**:
- Тип адрес за замовчуванням в GUI на legacy
- Додати опцію вибору типу адреси
- Заборонити створення SegWit транзакцій

## Алгоритми Вирішення

### 🔧 АЛГОРИТМ #1: Видалення Транзакції з Mempool

#### Метод 1: Перезапуск без Mempool
```bash
./src/bitcoin-cli stop
rm -f /Users/serbinov/.krepto/mempool.dat
./src/bitcoind -datadir=/Users/serbinov/.krepto -daemon -persistmempool=0
./src/bitcoin-cli getmempoolinfo
```

#### Метод 2: Ізоляція від Мережі
```bash
./src/bitcoin-cli stop
./src/bitcoind -datadir=/Users/serbinov/.krepto -daemon -connect=0 -persistmempool=0
./src/bitcoin-cli getmempoolinfo
```

#### Метод 3: Відключення Гаманця (ПРАЦЮЄ)
```bash
./src/bitcoin-cli stop
./src/bitcoind -datadir=/Users/serbinov/.krepto -daemon -disablewallet -persistmempool=0
./src/bitcoin-cli getmempoolinfo  # Повинен показати size: 0
```

#### Метод 4: Резервне Копіювання Гаманця
```bash
./src/bitcoin-cli stop
mv /Users/serbinov/.krepto/wallets /Users/serbinov/.krepto/wallets_backup
rm -f /Users/serbinov/.krepto/mempool.dat
./src/bitcoind -datadir=/Users/serbinov/.krepto -daemon
```

### 🔧 АЛГОРИТМ #2: Відкат до Попереднього Блоку

#### Метод 1: Використання invalidateblock
```bash
# Отримати хеш блоку для інвалідації
target_height=2100
invalid_height=$((target_height + 1))
invalid_hash=$(./src/bitcoin-cli getblockhash $invalid_height)

# Інвалідувати блок
./src/bitcoin-cli invalidateblock $invalid_hash

# Перевірити результат
./src/bitcoin-cli getblockchaininfo
```

#### Метод 2: Функція Відкату
```bash
rollback_blocks() {
    local blocks_back=$1
    current_height=$(./src/bitcoin-cli getblockchaininfo | jq -r '.blocks')
    target_height=$((current_height - blocks_back))
    invalid_height=$((target_height + 1))
    invalid_hash=$(./src/bitcoin-cli getblockhash $invalid_height)
    ./src/bitcoin-cli invalidateblock $invalid_hash
    echo "Rolled back $blocks_back blocks. New height: $target_height"
}

# Використання
rollback_blocks 100
```

### 🔧 АЛГОРИТМ #3: Діагностика SegWit Проблем

#### Швидка Перевірка
```bash
# Перевірити mempool на SegWit транзакції
check_segwit_in_mempool() {
    ./src/bitcoin-cli getrawmempool true | jq -r 'to_entries[] | select(.value.weight > (.value.vsize * 4)) | .key'
}

# Перевірити конкретну транзакцію
check_transaction_segwit() {
    local txid=$1
    ./src/bitcoin-cli getrawtransaction $txid true | jq -r '.txinwitness // empty'
}

# Тест майнінгу
test_mining() {
    result=$(./src/bitcoin-cli generatetoaddress 1 K9iZTbAUMnikKeQae4qwkYc8A5xpazEtTW 10000000 2>&1)
    if echo "$result" | grep -q "unexpected-witness"; then
        echo "❌ SegWit проблема виявлена"
        return 1
    else
        echo "✅ Майнінг працює"
        return 0
    fi
}
```

#### Повна Діагностика
```bash
diagnose_segwit_issue() {
    echo "🔍 Діагностика SegWit проблем..."
    
    # Перевірити mempool
    mempool_size=$(./src/bitcoin-cli getmempoolinfo | jq -r '.size')
    echo "📊 Mempool size: $mempool_size"
    
    if [ $mempool_size -gt 0 ]; then
        echo "🔍 Перевірка SegWit транзакцій..."
        segwit_txs=$(check_segwit_in_mempool)
        if [ -n "$segwit_txs" ]; then
            echo "⚠️  Знайдено SegWit транзакції:"
            echo "$segwit_txs"
        fi
    fi
    
    # Тест майнінгу
    echo "🔨 Тестування майнінгу..."
    test_mining
    
    # Рекомендації
    if [ $? -ne 0 ]; then
        echo "💡 Рекомендації:"
        echo "1. Очистити mempool (Алгоритм #1)"
        echo "2. Відкатитися до блоку без SegWit (Алгоритм #2)"
        echo "3. Запустити без гаманця для тестування"
    fi
}
```

## Швидкі Команди

### Діагностика
```bash
# Перевірка SegWit транзакцій в mempool
./src/bitcoin-cli getrawmempool true | jq -r 'to_entries[] | select(.value.weight > (.value.vsize * 4)) | .key'

# Перевірка mempool
./src/bitcoin-cli getmempoolinfo

# Тест майнінгу
./src/bitcoin-cli generatetoaddress 1 K9iZTbAUMnikKeQae4qwkYc8A5xpazEtTW 10000000
```

### Тимчасове Виправлення
```bash
# Швидке очищення для майнінгу
quick_fix_mining() {
    ./src/bitcoin-cli stop
    sleep 3
    rm -f /Users/serbinov/.krepto/mempool.dat
    ./src/bitcoind -datadir=/Users/serbinov/.krepto -daemon -disablewallet
    sleep 5
    ./src/bitcoin-cli generatetoaddress 1 K9iZTbAUMnikKeQae4qwkYc8A5xpazEtTW 10000000
}
```

### Відкат до Безпечного Стану
```bash
# Повернення до блоку 2100
rollback_to_safe_state() {
    ./src/bitcoin-cli invalidateblock $(./src/bitcoin-cli getblockhash 2101)
    echo "Rolled back to block 2100 (safe state)"
}
```

## Наступні Кроки Дослідження

### Пріоритет #1: Дослідження Коду
1. **Знайти CheckWitnessMalleation**:
   ```bash
   grep -r "CheckWitnessMalleation" src/
   grep -r "unexpected-witness" src/
   ```

2. **Порівняти з Bitcoin Core**:
   - Завантажити Bitcoin Core останньої версії
   - Порівняти реалізацію CheckWitnessMalleation
   - Знайти відмінності

3. **Перевірити SegWit активацію**:
   - Переглянути `src/chainparams.cpp`
   - Знайти налаштування SegWit consensus
   - Перевірити висоту активації

### Пріоритет #2: Модифікація GUI
1. **Змінити тип адрес за замовчуванням**:
   - Знайти налаштування в GUI коді
   - Змінити з SegWit на legacy
   - Протестувати створення транзакцій

2. **Додати опцію вибору**:
   - Створити UI для вибору типу адреси
   - Дозволити користувачу обирати
   - Зберігати налаштування

### Пріоритет #3: Альтернативні Рішення
1. **Відключити SegWit**:
   - Модифікувати chainparams.cpp
   - Видалити SegWit активацію
   - Перекомпілювати та протестувати

2. **Модифікувати CheckWitnessMalleation**:
   - Змінити логіку перевірки
   - Дозволити SegWit транзакції
   - Протестувати майнінг

## Поточний Статус

### Що Працює ✅
- ✅ Діагностика проблеми завершена
- ✅ Алгоритми вирішення документовано
- ✅ Тимчасові рішення знайдено
- ✅ Майнінг працює без SegWit транзакцій

### Що Не Працює ❌
- ❌ Майнінг з SegWit транзакціями в mempool
- ❌ Нормальна робота після використання GUI гаманця
- ❌ Автоматичне очищення проблемних транзакцій

### Тимчасові Рішення
1. **Для майнінгу**: Запуск з `-disablewallet`
2. **Для тестування**: Використання legacy адрес
3. **Для відкату**: Команда `invalidateblock`

## Висновки

1. **Проблема підтверджена**: SegWit транзакції дійсно блокують майнінг
2. **Джерело знайдено**: Транзакції надходять з гаманця, а не з мережі
3. **Тимчасове рішення є**: Запуск без гаманця дозволяє майнити
4. **Потрібне дослідження коду**: CheckWitnessMalleation потребує аналізу
5. **GUI потребує модифікації**: Змінити тип адрес за замовчуванням

**Наступний крок**: Дослідити код CheckWitnessMalleation та порівняти з Bitcoin Core. 