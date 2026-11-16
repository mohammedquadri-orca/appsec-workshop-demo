# Orca AppSec demo image – remediated.
# Fixed: pinned slim base, COPY, non-root USER, HEALTHCHECK, no secrets in ENV.
FROM python:3.11-slim

ARG REPO_URL=https://github.com/CHANGE_ME/appsec-workshop-demo
ARG GIT_SHA=unknown

LABEL org.opencontainers.image.title="orca-appsec-demo" \
      org.opencontainers.image.description="Intentionally vulnerable Flask app for the Orca AppSec end-to-end demo" \
      org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      com.orcasecurity.demo.marker="orca-c2d-7f3a9c41" \
      com.orcasecurity.demo.owner-team="appsec-demo"

ENV PYTHONUNBUFFERED=1 \
    PORT=8080 \
    DEMO_DB_PATH=/opt/orca-appsec-demo/data/demo.db

WORKDIR /opt/orca-appsec-demo

COPY app/requirements.txt /opt/orca-appsec-demo/app/requirements.txt
RUN pip install --no-cache-dir -r /opt/orca-appsec-demo/app/requirements.txt

RUN groupadd --system --gid 10001 app \
 && useradd --system --uid 10001 --gid app --no-create-home app \
 && mkdir -p /opt/orca-appsec-demo/data \
 && echo "orca-appsec-demo build marker orca-c2d-7f3a9c41" > /opt/orca-appsec-demo/.orca-demo-marker \
 && chown -R app:app /opt/orca-appsec-demo/data

COPY app /opt/orca-appsec-demo/app

USER 10001:10001
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=2).status == 200 else 1)"

ENTRYPOINT ["python", "-m", "app.main"]
