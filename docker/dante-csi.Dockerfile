# Dante Labs: upstream juicefs-csi-driver image with its Debian bookworm packages upgraded.
# Upstream builds on python:3.9.21-slim-bookworm and never upgrades it, so releases ship stale
# openssl/gnutls/perl (v0.33.3: 7 critical, 115 high fixable). The driver binary is unchanged.
ARG CSI_TAG=v0.33.3
FROM juicedata/juicefs-csi-driver:${CSI_TAG}
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade \
 && apt-get clean && rm -rf /var/lib/apt/lists/*
