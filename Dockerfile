# syntax=docker/dockerfile:1
# Distroless-when-possible template for augustus.
# Installs package from Bioconda and copies one selected executable + shared libs (if ELF).

FROM mambaorg/micromamba:2.0.5-debian12-slim AS builder

RUN micromamba install -y -n base -c conda-forge -c bioconda \
    augustus \
    && micromamba clean --all --yes

# Resolve a runnable command for this package.
# Prefer exact match, then underscore variant, then prefix match.
RUN set -eux; \
    BIN=""; \
    if [ -x "/opt/conda/bin/augustus" ]; then BIN="/opt/conda/bin/augustus"; fi; \
    if [ -z "$BIN" ]; then CAND="/opt/conda/bin/$(echo augustus | tr '-' '_')"; [ -x "$CAND" ] && BIN="$CAND" || true; fi; \
    if [ -z "$BIN" ]; then BIN="$(find /opt/conda/bin -maxdepth 1 -type f -perm -111 -name 'augustus*' | head -n1 || true)"; fi; \
    test -n "$BIN"; \
    cp -f "$BIN" /tmp/tool-entry && chmod +x /tmp/tool-entry

USER root

# Collect runtime shared libraries for distroless image when binary is ELF.
RUN mkdir -p /tmp/runtime-libs && \
    (ldd "/tmp/tool-entry" 2>/dev/null || true) | \
    awk '/=> \/|^\// {for(i=1;i<=NF;i++) if ($i ~ /^\//) print $i}' | sort -u | \
    xargs -r -I{} cp -v --parents "{}" /tmp/runtime-libs || true

FROM gcr.io/distroless/base-debian12

COPY --from=builder /tmp/tool-entry /usr/local/bin/augustus
COPY --from=builder /tmp/runtime-libs/ /

WORKDIR /data
ENTRYPOINT ["/usr/local/bin/augustus"]
