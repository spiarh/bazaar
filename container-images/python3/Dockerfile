FROM docker.io/spiarh/alpine:latest

RUN apk add --no-cache python3 py3-requests py3-yaml && \
    pip3 install --no-cache --upgrade pip setuptools wheel

WORKDIR /app

ENTRYPOINT ["python3"]
