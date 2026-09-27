# checkov:skip=CKV_DOCKER_2:Kubernetes probes check health; Docker's HEALTHCHECK is ignored there

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && pip uninstall -y setuptools wheel

COPY app.py .

# Run as a non-root user: a container escape doesn't start with root
RUN useradd --uid 10001 --no-create-home app
USER 10001

EXPOSE 8080
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
