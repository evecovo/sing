FROM alpine:3.20 AS builder
RUN apk add --no-cache curl jq tar
ARG TARGETARCH
ARG SB_VER_TAG

RUN set -eux; \
    SB_VER=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r '.tag_name' | sed 's/^v//'); \
    case "$TARGETARCH" in \
      amd64) ARCH=amd64 ;; \
      arm64) ARCH=arm64 ;; \
    esac; \
    curl -Lo /tmp/sb.tar.gz https://github.com/SagerNet/sing-box/releases/download/v${SB_VER}/sing-box-${SB_VER}-linux-${ARCH}.tar.gz; \
    tar -xzf /tmp/sb.tar.gz -C /tmp; \
    mv /tmp/sing-box-*/sing-box /usr/local/bin/sing-box

FROM alpine:3.20
RUN apk add --no-cache bash ca-certificates curl

COPY --from=builder /usr/local/bin/sing-box /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV UUID="" \
    DEST_DOMAIN="www.microsoft.com" \
    PORT=443 \
    GOGC=50

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
