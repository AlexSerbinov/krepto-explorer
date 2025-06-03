# Налаштування Nginx для krepto.com

## Підготовка

1. **Переконайтеся, що сертифікати SSL вже створені:**
   ```bash
   sudo certbot --nginx -d krepto.com -d www.krepto.com
   ```

2. **Створіть директорію для статичних файлів:**
   ```bash
   sudo mkdir -p /var/www/html/krepto.com
   sudo chown -R www-data:www-data /var/www/html/krepto.com
   ```

3. **Створіть простий index.html для тестування:**
   ```bash
   sudo tee /var/www/html/krepto.com/index.html > /dev/null << 'EOF'
   <!DOCTYPE html>
   <html lang="uk">
   <head>
       <meta charset="UTF-8">
       <meta name="viewport" content="width=device-width, initial-scale=1.0">
       <title>Krepto - Революційна Криптовалюта</title>
       <style>
           body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
           .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
           h1 { color: #333; text-align: center; }
           .explorer-link { display: inline-block; background: #007bff; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
       </style>
   </head>
   <body>
       <div class="container">
           <h1>Добро пожаловать на Krepto.com</h1>
           <p>Krepto - це інноваційна криптовалюта, базована на Bitcoin Core з унікальними особливостями.</p>
           <a href="/explorer/" class="explorer-link">Переглянути Explorer →</a>
       </div>
   </body>
   </html>
   EOF
   ```

## Активація конфігурації

1. **Скопіюйте конфігурацію Nginx:**
   ```bash
   sudo cp /etc/nginx/sites-available/krepto.com /etc/nginx/sites-available/krepto.com.backup
   # Потім скопіюйте новий файл конфігурації
   ```

2. **Увімкніть сайт:**
   ```bash
   sudo ln -sf /etc/nginx/sites-available/krepto.com /etc/nginx/sites-enabled/
   ```

3. **Перевірте синтаксис конфігурації:**
   ```bash
   sudo nginx -t
   ```

4. **Перезапустіть Nginx:**
   ```bash
   sudo systemctl reload nginx
   ```

## Перевірка роботи

1. **Головна сторінка:** https://krepto.com/
2. **Explorer:** https://krepto.com/explorer/
3. **Редиректи:**
   - http://krepto.com → https://krepto.com
   - https://www.krepto.com → https://krepto.com
   - https://krepto.com/blocks → https://krepto.com/explorer/blocks

## Моніторинг логів

```bash
# Налаштуйте ротацію логів
sudo tee /etc/logrotate.d/krepto-nginx > /dev/null << 'EOF'
/var/log/nginx/krepto.com-*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 www-data adm
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
EOF

# Перегляд логів в реальному часі
sudo tail -f /var/log/nginx/krepto.com-access.log
sudo tail -f /var/log/nginx/krepto.com-error.log
```

## Важливі особливості конфігурації

1. **Порядок location блоків критично важливий:**
   - `location = /` - точне співпадіння для головної сторінки
   - `location ~ ^/(style|css|js|...)` - статичні ресурси explorer'а
   - `location /explorer/` - проксі на backend
   - `location ~ ^/(blocks|transaction|...)` - редиректи
   - `location ~ \.php$` - PHP файли
   - `location /` - загальний fallback

2. **Explorer backend очікує заголовки:**
   - `X-Forwarded-Prefix: /explorer`
   - `X-Script-Name: /explorer`

3. **Безпека:**
   - SSL/TLS сертифікати
   - Безпекові заголовки
   - Заборона доступу до чутливих файлів

## Налагодження проблем

Якщо виникають проблеми:

```bash
# Перевірте статус служб
sudo systemctl status nginx
sudo systemctl status php8.1-fpm

# Перевірте підключення до backend
curl -I http://localhost:12348/

# Перевірте доступність файлів
ls -la /var/www/html/krepto.com/
``` 