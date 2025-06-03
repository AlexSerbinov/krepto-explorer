#!/bin/bash

echo "🔧 Testing Nginx Configuration for krepto.com"
echo "============================================="

# Test nginx syntax
echo "1. Testing Nginx syntax..."
if sudo nginx -t; then
    echo "✅ Nginx syntax is OK"
else
    echo "❌ Nginx syntax error - fix before proceeding"
    exit 1
fi

# Test backend connection
echo ""
echo "2. Testing backend connection..."
if curl -s -I http://localhost:12348/ | head -1; then
    echo "✅ Backend is responding"
else
    echo "❌ Backend not responding on localhost:12348"
fi

# Test specific asset paths that might be causing issues
echo ""
echo "3. Testing static asset paths..."

# Common asset paths from explorer
test_paths=(
    "/style/dark-v1.min.css"
    "/style/light.min.css"
    "/style/dark.min.css"
    "/style/bootstrap-icons.css"
    "/js/jquery.min.js"
    "/js/bootstrap.bundle.min.js"
    "/js/site.js"
    "/img/network-mainnet/apple-touch-icon.png"
    "/img/network-mainnet/favicon-32x32.png"
    "/img/network-mainnet/logo.svg"
)

for path in "${test_paths[@]}"; do
    echo "Testing: http://localhost:12348$path"
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:12348$path)
    if [[ $response == "200" ]]; then
        echo "✅ $path - OK ($response)"
    else
        echo "❌ $path - Failed ($response)"
    fi
done

echo ""
echo "4. Checking current nginx configuration..."
echo "Active sites:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "5. Recent nginx error logs:"
sudo tail -10 /var/log/nginx/krepto.com-error.log 2>/dev/null || echo "No error logs found"

echo ""
echo "6. Testing domain resolution..."
if curl -s -I https://krepto.com/explorer/ | head -1; then
    echo "✅ Domain is accessible"
else
    echo "❌ Domain not accessible"
fi

echo ""
echo "🔍 Debug commands to run manually:"
echo "sudo tail -f /var/log/nginx/krepto.com-access.log"
echo "sudo tail -f /var/log/nginx/krepto.com-error.log"
echo "curl -I https://krepto.com/css/theme.css"
echo "curl -I https://krepto.com/explorer/" 