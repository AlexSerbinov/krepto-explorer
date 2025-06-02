# Krepto Explorer

## Blockchain Explorer для Krepto криптовалюти

Це налаштований BTC RPC Explorer для роботи з блокчейном Krepto - форком Bitcoin з власними характеристиками.

### Особливості Krepto

- **Тікер**: KREPTO
- **Алгоритм**: SHA256
- **Винагорода за блок**: 50 KREPTO
- **Час блоку**: ~10 хвилин
- **Максимальна кількість**: 21,000,000 KREPTO

### Мережеві параметри

- **P2P порт**: 12345
- **RPC порт**: 12347
- **Magic bytes**: 0x4b, 0x52, 0x45, 0x50 (KREP)
- **Bech32 префікс**: "kr"

### Налаштування Explorer

Explorer налаштований для роботи з Krepto нодою:

- **RPC з'єднання**: localhost:12347
- **Веб-інтерфейс**: порт 3000
- **Txindex**: Увімкнений для повної функціональності

### Запуск

```bash
npm install
npm start
```

Explorer буде доступний за адресою: http://localhost:3000

### Конфігурація

Створіть файл `.env` з налаштуваннями:

```env
BTCEXP_COIN=BTC
BTCEXP_HOST=0.0.0.0
BTCEXP_PORT=3000
BTCEXP_BITCOIND_HOST=127.0.0.1
BTCEXP_BITCOIND_PORT=12347
BTCEXP_BITCOIND_USER=kreptouser
BTCEXP_BITCOIND_PASS=ваш_пароль
BTCEXP_NO_RATES=true
BTCEXP_UI_THEME=dark
```

### Функціональність

- ✅ Перегляд блоків та транзакцій
- ✅ Пошук за адресами/хешами
- ✅ Статистика майнінгу та мережі
- ✅ RPC Terminal
- ✅ Аналітика блокчейну
- ✅ API для розробників

### Базований на

Оригінальний [BTC RPC Explorer](https://github.com/janoside/btc-rpc-explorer) від janoside.

### Memory Bank

Проєкт включає повну документацію розробки Krepto блокчейну в папці `krepto-blockchain-memory-bank/`. 