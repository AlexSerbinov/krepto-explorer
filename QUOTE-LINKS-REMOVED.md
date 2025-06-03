# Видалення клікабельних посилань з цитат у Footer

## Проблема
Цитата в footer сторінки (наприклад, "Crypto is now Krepto" від Katoshi Babamoto) була клікабельною та переводила користувачів на окрему сторінку цитати, що було небажано.

## Рішення

### 1. Оновлення mixin quote
**Файл**: `views/includes/shared-mixins.pug`

Додано новий параметр `noLinks` до mixin `quote`:

```pug
// БУЛО:
mixin quote(quote, quoteIndex=-1, options={fontSize: 3, align:"start", includeQuotes:false})

// СТАЛО:
mixin quote(quote, quoteIndex=-1, options={fontSize: 3, align:"start", includeQuotes:false, noLinks:false})
```

**Логіка відображення:**
```pug
if (noLinks)
    span #{quote.text}
else if (quoteIndex >= 0)
    a.text-reset(href=`./quote/${quoteIndex}`) #{quote.text}
else
    span #{quote.text}
```

### 2. Оновлення snippet quote
**Файл**: `views/snippets/quote.pug`

Додано параметр `noLinks: true`:

```pug
// БУЛО:
+quote(quote, quoteIndex, {fontSize: 4, includeQuotes:true})

// СТАЛО:
+quote(quote, quoteIndex, {fontSize: 4, includeQuotes:true, noLinks:true})
```

## Результат

### Footer цитати:
- ❌ Більше не клікабельні
- ✅ Відображаються як простий текст
- ✅ Зберігається стилізація

### Сторінка цитат (/quotes):
- ✅ Посилання залишаються активними (параметр `noLinks` не використовується)
- ✅ Функціональність не порушена

### Окремі сторінки цитат (/quote/{id}):
- ✅ Продовжують працювати нормально

## Технічні деталі

- Mixin `quote` тепер підтримує параметр `noLinks` для відключення посилань
- За замовчуванням `noLinks = false`, тому існуюча функціональність не порушена
- Footer використовує `noLinks: true` для відображення тексту без посилань
- Всі інші використання mixin залишаються без змін

## Тестування

```bash
# Перевірка footer цитати (не має бути посилання)
curl -s http://localhost:12348/snippet/quote/random | grep "Crypto is now Krepto"
# Результат: <span>Crypto is now Krepto</span>

# Перевірка сторінки цитат (має бути 200 OK)
curl -I http://localhost:12348/quotes
# Результат: HTTP/1.1 200 OK
``` 