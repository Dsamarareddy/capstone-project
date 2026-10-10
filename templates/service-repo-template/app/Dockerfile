# syntax=docker/dockerfile:1
# TODO(new-service): keep this contract (multi-stage, non-root, HEALTHCHECK) even as you customize the app.

FROM python:3.12-alpine AS deps
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-alpine AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=3000
WORKDIR /app

RUN addgroup -g 1001 appuser && adduser -D -H -u 1001 -G appuser -s /sbin/nologin appuser

# Pull latest patched OS packages from Alpine's repos at build time.
RUN apk update && apk upgrade --no-cache

COPY --from=deps /install /usr/local
COPY service ./service

# The runtime never installs packages, so drop pip/setuptools (and their CVEs) from the final image.
RUN pip uninstall -y pip setuptools wheel 2>/dev/null || true

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import sys, urllib.request; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:3000/health').status == 200 else 1)"

CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT} --workers 2 --access-logfile - 'service.app:create_app()'"]
