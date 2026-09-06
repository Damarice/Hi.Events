#!/bin/sh

cd /app/backend

echo "Waiting for database to be ready..."

# Wait for database to be available (up to 30 seconds)
for i in {1..30}; do
    if php artisan db:show > /dev/null 2>&1; then
        echo "✓ Database is ready"
        break
    fi
    echo "Waiting for database... ($i/30)"
    sleep 1
done

echo "Running migrations..."
if ! php artisan migrate --force; then
    echo "============================================"
    echo "ERROR: Migrations could not complete. Check the error above."
    echo "Ensure DB_HOST, DB_PORT, DB_DATABASE, DB_USERNAME, and DB_PASSWORD are set."
    echo "Aborting startup to avoid running a half-migrated application."
    echo "============================================"
    exit 1
fi

echo "Clearing caches..."
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan storage:link

echo "Setting permissions..."
chown -R www-data:www-data /app/backend
chmod -R 775 /app/backend/storage /app/backend/bootstrap/cache

echo "Starting supervisor..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
