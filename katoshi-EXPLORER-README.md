# Krepto Explorer

## Blockchain Explorer для Krepto криптовалюти

Це налаштований KREPTO RPC Explorer для роботи з блокчейном Krepto - форком Krepto з власними характеристиками.

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
KREPTOEXP_COIN=KREPTO
KREPTOEXP_HOST=0.0.0.0
KREPTOEXP_PORT=3000
KREPTOEXP_KREPTOD_HOST=127.0.0.1
KREPTOEXP_KREPTOD_PORT=12347
KREPTOEXP_KREPTOD_USER=kreptouser
KREPTOEXP_KREPTOD_PASS=ваш_пароль
KREPTOEXP_NO_RATES=true
KREPTOEXP_UI_THEME=dark
```

### Функціональність

- ✅ Перегляд блоків та транзакцій
- ✅ Пошук за адресами/хешами
- ✅ Статистика майнінгу та мережі
- ✅ RPC Terminal
- ✅ Аналітика блокчейну
- ✅ API для розробників

### Базований на

Оригінальний [KREPTO RPC Explorer](https://github.com/janoside/krepto-rpc-explorer) від janoside.

### Memory Bank

Проєкт включає повну документацію розробки Krepto блокчейну в папці `krepto-blockchain-memory-bank/`. 