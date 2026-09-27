# checkov:skip=CKV_DOCKER_2:Kubernetes probes check health; Docker's HEALTHCHECK is ignored there

# nginx image that runs as a non-root user and listens on 8080
FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

# Non-root user (already the image's default, now explicit)
USER 101

EXPOSE 8080
