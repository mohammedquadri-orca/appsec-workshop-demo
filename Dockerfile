# Orca AppSec demo image – INTENTIONALLY violates Dockerfile best practices.
# Every violation is marked ORCA-DEMO. The fixed version lives on the
# fix/remediate-findings branch.
#
# Distinctive LABELs and the unique RUN marker below make Orca's
# image-history -> Dockerfile (Cloud-to-Dev) match easy to point at.

# ORCA-DEMO: IaC/Dockerfile – base image uses the mutable `latest` tag (unpinned, drifts over time)
FROM python:latest

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

# ORCA-DEMO: Secret – FAKE AWS credentials baked into the image via ENV (visible in image history)
ENV AWS_ACCESS_KEY_ID=AKIAU5VKD7OOMP2R3QPK \
    AWS_SECRET_ACCESS_KEY=mloHPZeapxul5MAR1DHjD9UJNd6QS3fUKU7EAgOH

WORKDIR /opt/orca-appsec-demo

# ORCA-DEMO: IaC/Dockerfile – ADD used instead of COPY for local files
ADD app/requirements.txt /opt/orca-appsec-demo/app/requirements.txt
RUN pip install --no-cache-dir -r /opt/orca-appsec-demo/app/requirements.txt

# Unique build step – shows up verbatim in the image history for Cloud-to-Dev matching
RUN mkdir -p /opt/orca-appsec-demo/data \
 && echo "orca-appsec-demo build marker orca-c2d-7f3a9c41" > /opt/orca-appsec-demo/.orca-demo-marker

# ORCA-DEMO: IaC/Dockerfile – ADD used instead of COPY for local files
ADD app /opt/orca-appsec-demo/app

EXPOSE 8080

# ORCA-DEMO: IaC/Dockerfile – no USER instruction, container runs as root
# ORCA-DEMO: IaC/Dockerfile – no HEALTHCHECK instruction
# Entry point starts the Flask app, so app.routes -> yaml.load (PyYAML 5.3.1) is on an executed path
ENTRYPOINT ["python", "-m", "app.main"]
