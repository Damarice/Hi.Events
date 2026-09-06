#!/bin/sh

cd /app/backend

echo "============================================"
echo "🚀 Hi.Events Startup Script"
echo "============================================"

# Print environment info for debugging
echo ""
echo "Database Configuration:"
echo "  DB_CONNECTION: ${DB_CONNECTION:-not set}"
echo "  DB_HOST: ${DB_HOST:-not set}"
echo "  DB_PORT: ${DB_PORT:-not set}"
echo "  DB_DATABASE: ${DB_DATABASE:-not set}"
echo "  DB_USERNAME: ${DB_USERNAME:-not set}"
echo ""

# Check if database variables are set
if [ -z "$DB_HOST" ] || [ -z "$DB_DATABASE" ]; then
    echo "⚠️  Database environment variables not configured!"
    echo "Please set the following environment variables in Render:"
    echo "  - DB_HOST"
    echo "  - DB_PORT"
    echo "  - DB_DATABASE"
    echo "  - DB_USERNAME"
    echo "  - DB_PASSWORD"
    echo ""
    echo "For now, starting app without database migrations..."
else
    echo "✓ Database variables detected, attempting connection..."
    
    # Wait for database to be available (up to 60 seconds)
    echo ""
    echo "Waiting for database to be ready..."
    for i in $(seq 1 60); do
        if php artisan db:show > /dev/null 2>&1; then
            echo "✓ Database is ready!"
            
            echo ""
            echo "Running migrations..."
            if php artisan migrate --force; then
                echo "✓ Migrations completed successfully"
            else
                echo "⚠️  Migrations had issues but continuing startup..."
            fi
            break
        fi
        
        if [ $((i % 10)) -eq 0 ]; then
            echo "Waiting for database... ($i/60 seconds)"
        fi
        sleep 1
    done
fi

echo ""
echo "Clearing caches..."
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "Creating storage link..."
php artisan storage:link || true

echo "Setting permissions..."
chown -R www-data:www-data /app/backend
chmod -R 775 /app/backend/storage /app/backend/bootstrap/cache

echo ""
echo "✓ Starting supervisor..."
echo "============================================"
echo ""

exec /usr/bin/supervisord -c /etc/supervisord.conf
