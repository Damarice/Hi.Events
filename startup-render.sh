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

exec /usr/bin/supervisord -c /etc/supervisord.conf

