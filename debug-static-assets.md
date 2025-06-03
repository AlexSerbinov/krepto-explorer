# Діагностика проблем зі статичними ресурсами Explorer

## Проблема
Explorer завантажується, але CSS стилі та зображення не відображаються. Сторінка виглядає як pure HTML без оформлення.

## Кроки діагностики

### 1. Перезапустіть Nginx з новою конфігурацією
```bash
sudo nginx -t && sudo systemctl reload nginx
```

### 2. Запустіть тестовий скрипт
```bash
./test-nginx-config.sh
```

### 3. Перевірте логи в реальному часі
Відкрийте 2 термінали:

**Термінал 1:**
```bash
sudo tail -f /var/log/nginx/krepto.com-access.log
```

**Термінал 2:**
```bash
sudo tail -f /var/log/nginx/krepto.com-error.log
```

### 4. Тестуйте конкретні статичні ресурси
```bash
# Перевірте доступність через Nginx
curl -I https://krepto.com/css/theme.css
curl -I https://krepto.com/style/bootstrap.min.css
curl -I https://krepto.com/img/network-mainnet/logo.svg

# Перевірте доступність напряму до backend
curl -I http://localhost:12348/css/theme.css
curl -I http://localhost:12348/style/bootstrap.min.css
```

### 5. Перевірте що генерує Explorer
Відкрийте Developer Tools в браузері (F12) та:
1. Перейдіть на вкладку "Network"
2. Перезавантажте сторінку krepto.com/explorer/
3. Подивіться які ресурси завантажуються з помилками (червоні)

### 6. Тимчасове рішення для тестування
Якщо проблема лишається, спробуйте цю спрощену конфігурацію:

```nginx
# Додайте це в /etc/nginx/sites-available/krepto.com перед location /explorer/
location ~* \.(css|js|png|jpg|jpeg|gif|svg|woff|woff2|ttf|eot|ico)$ {
    proxy_pass http://localhost:12348$request_uri;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Prefix /explorer;
    proxy_set_header X-Script-Name /explorer;
    
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 7. Перевірте baseUrl в Explorer
Можливо, Explorer генерує неправильні URL. Перевірте в браузері:
1. View Source на krepto.com/explorer/
2. Пошукайте посилання на CSS/JS файли
3. Перевірте чи правильні шляхи генеруються

### 8. Альтернативне рішення - обслуговування через /explorer/
Якщо проблема не розв'язується, можна налаштувати Explorer щоб всі ресурси обслуговувались через префікс /explorer/:

```nginx
# Замість обробки "голих" шляхів, обслуговувати все через /explorer/
location /explorer/ {
    proxy_pass http://localhost:12348/;
    # ... інші налаштування
}

# І видалити блоки для "голих" статичних ресурсів
```

### 9. Очікувані результати
Після успішного виправлення:
- CSS стилі завантажуються
- Логотип показується як зображення, не як текст
- Сторінка має правильне оформлення
- В Network tab браузера всі ресурси завантажуються з кодом 200

### 10. Швидкий тест
```bash
# Якщо це працює напряму:
curl http://localhost:12348/css/theme.css

# То повинно працювати через Nginx:
curl https://krepto.com/css/theme.css
``` 