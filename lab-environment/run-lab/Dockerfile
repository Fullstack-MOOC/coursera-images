FROM --platform=linux/amd64 python:3.8-slim

RUN apt-get update && \
   apt-get install -y --no-install-recommends curl ca-certificates && \
   curl -sSL https://get.docker.com/ | sh && \
   apt-get clean && \
   rm -rf /var/lib/apt/lists/*

ENV TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

COPY run-lab/coursera-lab.py coursera-lab.py

ENTRYPOINT ["/tini", "--"]