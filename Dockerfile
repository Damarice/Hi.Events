FROM node:22-alpine AS node-frontend

WORKDIR /app/frontend

RUN apk add --no-cache yarn

# Increase network timeout for slow ARM emulation builds
RUN yarn config set network-timeout 600000

COPY ./frontend/package.json ./frontend/yarn.lock ./

COPY ./frontend .
COPY ./VERSION /app/VERSION

# Build frontend with environment variables
# These will be set by Render during the build process
ARG VITE_API_URL_CLIENT=https://hi-events-g3dx.onrender.com/api
ARG VITE_API_URL_SERVER=http://127.0.0.1/api

ENV VITE_API_URL_CLIENT=$VITE_API_URL_CLIENT
ENV VITE_API_URL_SERVER=$VITE_API_URL_SERVER
ENV NODE_ENV=production
# Ensure node_modules/.bin is in PATH for yarn scripts
ENV PATH="/app/frontend/node_modules/.bin:$PATH"

RUN echo "Installing frontend dependencies..." && \
    yarn install --network-timeout 600000 && \
    echo "✓ Frontend dependencies installed" && \
    echo "Building frontend..." && \
    yarn build && \
    echo "✓ Frontend build completed successfully" && \
    if [ -d "dist" ]; then \
        echo "✓ dist folder found"; \
        ls -lah dist/; \
        if [ -d "dist/client" ]; then echo "✓ dist/client found - $(find dist/client -type f | wc -l) files"; else echo "✗ dist/client NOT found"; exit 1; fi; \
        if [ -d "dist/server" ]; then echo "✓ dist/server found - $(find dist/server -type f | wc -l) files"; else echo "✗ dist/server NOT found"; exit 1; fi; \
    else \
        echo "✗ dist folder NOT found after build - build may have failed!"; \
        exit 1; \
    fi

# Use stable multi-arch serversideup/php image
FROM serversideup/php:8.5-fpm-alpine

ENV PHP_OPCACHE_ENABLE=1

# Switch to root for installing extensions and packages
USER root

RUN install-php-extensions intl gd

RUN apk add --no-cache nodejs yarn nginx supervisor dos2unix

COPY --from=node-frontend /app/frontend /app/frontend

COPY ./backend /app/backend
COPY ./VERSION /app/backend/VERSION
RUN mkdir -p /app/backend/bootstrap/cache \
    && mkdir -p /app/backend/storage \
    && chown -R www-data:www-data /app/backend \
    && find /app/backend -type d -exec chmod 755 {} \; \
    && find /app/backend -type f -exec chmod 644 {} \; \
    && chmod -R 755 /app/backend/storage /app/backend/bootstrap/cache \
    && composer install --working-dir=/app/backend \
        --ignore-platform-reqs \
        --no-interaction \
        --no-dev \
        --optimize-autoloader \
        --prefer-dist \
    && chmod -R 755 /app/backend/vendor/ezyang/htmlpurifier/library/HTMLPurifier/DefinitionCache/Serializer

COPY ./docker/all-in-one/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/all-in-one/supervisor/supervisord.conf /etc/supervisord.conf

COPY ./docker/all-in-one/scripts/startup.sh /startup.sh
COPY ./startup-render.sh /startup.sh
RUN dos2unix /startup.sh && chmod +x /startup.sh

EXPOSE 80

WORKDIR /app

CMD ["/startup.sh"]
