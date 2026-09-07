#!/bin/sh

cd /app/backend

echo "============================================"
echo "🚀 Hi.Events Startup Script"
echo "============================================"
echo ""

# Set permissions FIRST before anything else
echo "Setting permissions..."
mkdir -p /app/backend/storage/logs
mkdir -p /app/backend/bootstrap/cache
chown -R www-data:www-data /app/backend/storage
chown -R www-data:www-data /app/backend/bootstrap
chmod -R 777 /app/backend/storage
chmod -R 777 /app/backend/bootstrap/cache
echo "✓ Permissions set"
echo ""

# Check if frontend dist exists
echo "Checking frontend build..."
if [ -d "/app/frontend/dist" ]; then
    echo "✓ Frontend dist directory exists"
    echo "  Client build: $([ -d "/app/frontend/dist/client" ] && echo 'YES' || echo 'NO')"
    echo "  Server build: $([ -d "/app/frontend/dist/server" ] && echo 'YES' || echo 'NO')"
    if [ -f "/app/frontend/dist/client/index.html" ]; then
        echo "  index.html size: $(wc -c < /app/frontend/dist/client/index.html) bytes"
    fi
    if [ -d "/app/frontend/dist/client/assets" ]; then
        echo "  Assets found: $(ls -1 /app/frontend/dist/client/assets 2>/dev/null | wc -l) files"
        echo "  Asset samples:"
        ls -1 /app/frontend/dist/client/assets 2>/dev/null | head -5 | sed 's/^/    - /'
    fi
else
    echo "✗ Frontend dist directory NOT FOUND - frontend build may have failed!"
    echo "  Frontend directory contents:"
    ls -la /app/frontend/ | head -20
fi
echo ""

# Load environment
export $(cat /app/backend/.env 2>/dev/null | grep -v '#' | xargs) 2>/dev/null || true

echo "Configuration:"
echo "  APP_ENV: ${APP_ENV:-not set}"
echo "  APP_DEBUG: ${APP_DEBUG:-not set}"
echo "  DB_CONNECTION: ${DB_CONNECTION:-not set}"
echo "  JWT_SECRET set: $([ -z "$JWT_SECRET" ] && echo 'NO' || echo 'YES')"
echo "  APP_SAAS_MODE_ENABLED: ${APP_SAAS_MODE_ENABLED:-not set}"
echo ""

# Try to verify database connection
if [ -n "$DB_HOST" ] && [ -n "$DB_DATABASE" ]; then
    echo "Database host detected. Waiting for database..."
    COUNTER=0
    while [ $COUNTER -lt 60 ]; do
        if php artisan db:show > /dev/null 2>&1; then
            echo "✓ Database is ready"
            echo ""
            
            echo "Running migrations..."
            php artisan migrate --force 2>&1 || echo "⚠️  Migration warning (continuing anyway)"
            echo ""
            
            echo "Creating super admin accounts..."
            php artisan setup:create-super-admins 2>&1 || echo "⚠️  Super admin setup warning"
            echo ""
            break
        fi
        
        COUNTER=$((COUNTER + 1))
        if [ $((COUNTER % 15)) -eq 0 ]; then
            echo "Waiting for DB... ${COUNTER}s"
        fi
        sleep 1
    done
else
    echo "Database configuration incomplete, skipping migrations"
fi

echo "Clearing application cache..."
rm -rf /app/backend/bootstrap/cache/* 2>/dev/null || true
php artisan cache:clear 2>&1 || true
php artisan config:clear 2>&1 || true
php artisan route:clear 2>&1 || true

echo "Creating storage link..."
php artisan storage:link 2>&1 || true

echo ""
echo "✓ Startup complete, starting services..."
echo "============================================"
echo ""
echo "Services starting:"
echo "  - Nginx (port 80)"
echo "  - PHP-FPM (port 9000)"
echo "  - Node.js SSR server (port 5678)"
echo "  - Laravel queue worker"
echo "  - Laravel scheduler"
echo ""
echo "Application URLs:"
echo "  - Frontend: https://hi-events-g3dx.onrender.com"
echo "  - API: https://hi-events-g3dx.onrender.com/api"
echo ""

exec /usr/bin/supervisord -c /etc/supervisord.conf

