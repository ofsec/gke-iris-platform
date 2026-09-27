# checkov:skip=CKV_DOCKER_2:Kubernetes probes check health; Docker's HEALTHCHECK is ignored there

# nginx image that runs as a non-root user and listens on 8080
FROM nginxinc/nginx-unprivileged:1.31.6-alpine

# Apply Alpine security fixes released after this base image was built
USER root
RUN apk upgrade --no-cache

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY app.js style.css /usr/share/nginx/html/

# Non-root user (already the image's default, now explicit)
USER 101

EXPOSE 8080
