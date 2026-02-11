FROM node:18-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY . .
RUN npm run build

FROM nginx:1.25-alpine

RUN apk add --no-cache curl && \
    adduser -D -u 101 nginx || true

RUN mkdir -p /tmp/nginx/{client_body_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp} \
    /var/cache/nginx/{client_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp} && \
    chown -R nginx:nginx /tmp/nginx /var/cache/nginx /usr/share/nginx/html /var/log/nginx

COPY --from=build --chown=nginx:nginx /app/build /usr/share/nginx/html
COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf

# Configure nginx for read-only filesystem
RUN sed -i 's/^user/#user/' /etc/nginx/nginx.conf && \
    sed -i 's|pid.*nginx\.pid.*;|pid /var/run/nginx.pid;|' /etc/nginx/nginx.conf && \
    sed -i '/http {/a \    client_body_temp_path /var/cache/nginx/client_temp;\n    proxy_temp_path /var/cache/nginx/proxy_temp;\n    fastcgi_temp_path /var/cache/nginx/fastcgi_temp;\n    uwsgi_temp_path /var/cache/nginx/uwsgi_temp;\n    scgi_temp_path /var/cache/nginx/scgi_temp;' /etc/nginx/nginx.conf

USER nginx
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]