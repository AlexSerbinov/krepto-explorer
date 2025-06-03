# Nginx Конфігурація для Krepto Explorer

**Дата створення:** 3 червня 2025  
**Статус:** ✅ Працює в продакшені  
**Домен:** https://krepto.com  

## Огляд

Повна Nginx конфігурація для сайту krepto.com з підтримкою двох компонентів:
1. **Головна сторінка** - статичний HTML на кореневому домені
2. **Explorer додаток** - проксування на backend на `/explorer/`

## Файл Конфігурації

**Розташування:** `/etc/nginx/sites-available/krepto.com`

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name krepto.com www.krepto.com;
    return 301 https://krepto.com$request_uri;
}

# Redirect www.krepto.com to krepto.com (HTTPS)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name www.krepto.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/krepto.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/krepto.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/krepto.com/chain.pem;
    
    return 301 https://krepto.com$request_uri;
}

# Main server block for krepto.com
server {
    server_name krepto.com www.krepto.com;
    root /var/www/html/krepto.com;
    index index.html index.php index.htm;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Hide nginx version
    server_tokens off;

    # Explorer static assets (CSS/JS/Images) - MUST BE BEFORE /explorer/
    location ~ ^/(style|css|js|img|assets|static)/ {
        proxy_pass http://localhost:12348;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Prefix /explorer;
        proxy_set_header X-Script-Name /explorer;
        # Cache static assets
        expires 1h;
        add_header Cache-Control "public";
        # CORS for potential font access
        add_header Access-Control-Allow-Origin "*";
    }

    # Explorer fonts with proper CORS headers
    location ~ ^/(fonts|webfonts|font-awesome|fa)/ {
        proxy_pass http://localhost:12348;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Prefix /explorer;
        proxy_set_header X-Script-Name /explorer;
        # CORS headers for fonts
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type";
        # Cache fonts longer
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Specific font file extensions anywhere
    location ~* \.(woff|woff2|ttf|eot|otf)$ {
        proxy_pass http://localhost:12348;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Prefix /explorer;
        proxy_set_header X-Script-Name /explorer;
        # CORS headers for fonts
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type";
        # Cache fonts longer
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Explorer service proxy
    location /explorer/ {
        proxy_pass http://localhost:12348/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Prefix /explorer;
        proxy_set_header X-Script-Name /explorer;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
        
        # Important for binary files (PDF, images, etc.)
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_max_temp_file_size 0;
        
        # NO CACHE for HTML pages to prevent browser caching issues
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        
        # Pass through all original headers for downloads
        proxy_pass_header Content-Type;
        proxy_pass_header Content-Disposition;
        proxy_pass_header Content-Transfer-Encoding;
        proxy_pass_header Accept-Ranges;
        proxy_pass_header Content-Length;
    }

    # Explorer API endpoints
    location ~ ^/(api|snippet|changeSetting|search|admin|internal-api|build-mining-summary|mining-summary-status)(/.*)?$ {
        proxy_pass http://localhost:12348;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Prefix /explorer;
        proxy_set_header X-Script-Name /explorer;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # Explorer main endpoints (redirect from root to /explorer/)
    location ~ ^/(blocks|mempool-summary|mempool-transactions|next-block|mining-summary|utxo-set|block-stats|block-analysis|difficulty-history|tx-stats|next-halving|rpc-browser|rpc-terminal|peers|fun|quotes|holidays|krepto-whitepaper|node-details|user-settings|block-height|address|tx)(/.*)?$ {
        return 301 /explorer$request_uri;
    }

    # Additional redirects for explorer paths
    location ~ ^/block/(.*)$ {
        return 301 /explorer/block/$1;
    }

    location ~ ^/transaction/(.*)$ {
        return 301 /explorer/transaction/$1;
    }

    location ~ ^/address/(.*)$ {
        return 301 /explorer/address/$1;
    }

    # Handle root - main site (NO REDIRECTS)
    location = / {
        access_log /var/log/nginx/home-access.log;
        try_files $uri $uri/ /index.html /index.php?$args;
    }

    # WordPress support
    location /wp-admin/ {
        try_files $uri $uri/ /index.php?$args;
    }

    location /wp-content/ {
        try_files $uri $uri/ =404;
    }

    # Main site fallback
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP handling
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Security rules
    location ~* /(?:uploads|files)/.*\.php$ {
        deny all;
    }

    location ~ /\.ht {
        deny all;
    }

    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Logs
    access_log /var/log/nginx/krepto.com.access.log;
    error_log /var/log/nginx/krepto.com.error.log;

    # SSL certificates (managed by Certbot)
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/krepto.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/krepto.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
```

## Команди Управління

### Тестування конфігурації
```bash
sudo nginx -t
```

### Застосування змін
```bash
sudo systemctl reload nginx
```

### Перезапуск Nginx
```bash
sudo systemctl restart nginx
```

### Перегляд статусу
```bash
sudo systemctl status nginx
```

## Логи

- **Access log:** `/var/log/nginx/krepto.com.access.log`
- **Error log:** `/var/log/nginx/krepto.com.error.log`
- **Home access log:** `/var/log/nginx/home-access.log`

## Особливості Конфігурації

### 1. **Порядок Location Блоків**
Критично важливий порядок:
1. Статичні ресурси Explorer (`/style/`, `/css/`, `/js/`, `/img/`)
2. Шрифти Explorer (`/fonts/`, `/webfonts/`)
3. Explorer проксі (`/explorer/`)
4. API ендпоінти
5. Редиректи
6. Корінь сайту (`/`)

### 2. **Кешування**
- **HTML сторінки Explorer:** `no-cache` (запобігає проблемам з браузерним кешуванням)
- **CSS/JS:** 1 година кешування
- **Шрифти:** 1 рік кешування
- **Зображення:** 1 рік кешування

### 3. **CORS заголовки**
- Додано для шрифтів щоб уникнути CORS помилок
- `Access-Control-Allow-Origin: *` для статичних ресурсів

### 4. **Заголовки проксі**
Критичні заголовки для Explorer:
- `X-Forwarded-Prefix: /explorer`
- `X-Script-Name: /explorer`
- Дозволяють Express зрозуміти що він працює під префіксом

## SSL Сертифікати

Управляються через **Let's Encrypt Certbot**:

```bash
# Оновлення сертифікатів
sudo certbot renew

# Створення нових сертифікатів
sudo certbot --nginx -d krepto.com -d www.krepto.com
```

## Troubleshooting

### Якщо статичні ресурси не завантажуються:
1. Перевірити порядок location блоків
2. Перевірити що Explorer працює на localhost:12348
3. Перевірити логи: `tail -f /var/log/nginx/krepto.com.error.log`

### Якщо redirect loops:
1. Перевірити що `/` location не робить редиректи
2. Перевірити що Explorer посилання використовують абсолютні URL

### Якщо проблеми з кешуванням:
1. Очистити браузерний кеш (Ctrl+Shift+R)
2. Перевірити `Cache-Control` заголовки через curl
3. При потребі додати `?v=timestamp` до URL 