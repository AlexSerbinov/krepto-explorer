# Видалення RPC Browser та RPC Terminal з навігації

## Проблема
RPC Browser та RPC Terminal відображались в навігаційному меню сайту, але їх потрібно було приховати від публічного доступу, зберігши функціональність для прямого доступу з аутентифікацією.

## Зміни в коді

### 1. app/config.js
**Рядки 246-247**: Замінено активні елементи на `null`
```javascript
// БУЛО:
// /* 6 */		{name:"RPC Browser", url:"./rpc-browser", desc:"Browse the RPC functionality of this node. See docs and execute commands.", iconClass:"bi-journal-text"},
// /* 7 */		{name:"RPC Terminal", url:"./rpc-terminal", desc:"Directly execute RPCs against this node.", iconClass:"bi-terminal"},

// СТАЛО:
/* 6 */		null, // Removed: RPC Browser
/* 7 */		null, // Removed: RPC Terminal
```

**Рядок 231**: Видалено індекси 6 та 7 з `prioritizedToolIdsList`
```javascript
// БУЛО:
prioritizedToolIdsList: [0, 10, 11, 9, 3, 4, 16, 12, 2, 5, 15, 1, 6, 7, 13, 17],

// СТАЛО:
prioritizedToolIdsList: [0, 10, 11, 9, 3, 4, 16, 12, 2, 5, 15, 1, 13, 17],
```

**Рядок 236**: Видалено індекси 6 та 7 з секції "Technical" в `toolSections`
```javascript
// БУЛО:
{name: "Technical", items: [15, 6, 7, 1]},

// СТАЛО:
{name: "Technical", items: [15, 1]},
```

## Результат

### Без аутентифікації (публічний доступ):
- ✅ Сайт працює без проблем
- ❌ RPC Browser не відображається в навігації
- ❌ RPC Terminal не відображається в навігації
- ❌ Прямий доступ до `/rpc-browser` і `/rpc-terminal` показує повідомлення про необхідність аутентифікації

### З аутентифікацією:
- ✅ Сайт працює з паролем
- ✅ RPC Browser доступний за прямим URL `/rpc-browser`
- ✅ RPC Terminal доступний за прямим URL `/rpc-terminal`
- ❌ RPC інструменти НЕ відображаються в навігаційному меню (це бажана поведінка)

## Скрипти запуску

### Публічний доступ (без RPC):
```bash
./start-explorer-public.sh
```

### З аутентифікацією (з RPC):
```bash
./start-explorer-with-auth.sh
```

## Безпека
- RPC функції доступні тільки з аутентифікацією
- Публічні користувачі не бачать RPC інструментів в меню
- Прямий доступ до RPC URL-ів захищений

## Технічні деталі
- `siteTools` масив використовує `null` значення для видалених інструментів
- Template engine правильно обробляє `null` значення
- Всі посилання на індекси 6 та 7 видалені з конфігурації
- Роути `/rpc-browser` та `/rpc-terminal` залишаються активними, але захищеними 