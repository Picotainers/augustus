# syntax=docker/dockerfile:1

FROM debian:bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    build-essential \
    zlib1g-dev \
    libbamtools-dev \
    libboost-iostreams-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone --depth 1 https://github.com/Gaius-Augustus/Augustus.git

WORKDIR /opt/Augustus
RUN make -j"$(nproc)" COMPGENEPRED=false MYSQL=false SQLITE=false augustus

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    zlib1g \
    libbamtools2.5.2 \
    libboost-iostreams1.74.0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/Augustus/bin/augustus /usr/local/bin/augustus
COPY --from=builder /opt/Augustus/config /opt/augustus/config

ENV AUGUSTUS_CONFIG_PATH=/opt/augustus/config

RUN printf '%s\n' '#!/bin/sh' \
    'if [ "${1:-}" = "augustus" ]; then shift; fi' \
    'exec /usr/local/bin/augustus "$@"' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /data
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
