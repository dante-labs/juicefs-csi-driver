# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:1.25-bookworm as binaryimage

ARG GOPROXY
ARG TARGETARCH
ARG JUICEFS_REPO_URL=https://github.com/juicedata/juicefs
ARG JUICEFS_REPO_BRANCH=main
ARG JUICEFS_REPO_REF=${JUICEFS_REPO_BRANCH}
ARG CEPH_RELEASE=

# Optional: install librados from Ceph's own repo (e.g. CEPH_RELEASE=tentacle or squid) instead of Debian
# bookworm's (Pacific 16.2.x). Needed for cephx aes256k keys (CVE-2025-30156) and newer Ceph clusters.
# Empty (default) keeps the Debian packages.
RUN if [ -n "${CEPH_RELEASE}" ]; then \
      wget -qO- https://download.ceph.com/keys/release.asc | gpg --dearmor -o /usr/share/keyrings/ceph.gpg && \
      echo "deb [signed-by=/usr/share/keyrings/ceph.gpg] https://download.ceph.com/debian-${CEPH_RELEASE}/ bookworm main" \
        > /etc/apt/sources.list.d/ceph.list; \
    fi

RUN bash -c "if [[ ${TARGETARCH} == amd64 ]]; then mkdir -p /home/travis/.m2 && \
    wget -O /home/travis/.m2/foundationdb-clients_6.3.23-1_${TARGETARCH}.deb https://github.com/apple/foundationdb/releases/download/6.3.23/foundationdb-clients_6.3.23-1_${TARGETARCH}.deb && \
    dpkg -i /home/travis/.m2/foundationdb-clients_6.3.23-1_${TARGETARCH}.deb && \
    wget -O - https://download.gluster.org/pub/gluster/glusterfs/10/rsa.pub | apt-key add - && \
    echo deb [arch=${TARGETARCH}] https://download.gluster.org/pub/gluster/glusterfs/11/LATEST/Debian/bookworm/${TARGETARCH}/apt bookworm main > /etc/apt/sources.list.d/gluster.list && \
    apt-get update && apt-get install -y uuid-dev libglusterfs-dev glusterfs-common librados2 librados-dev; fi"

WORKDIR /workspace
ENV GOPROXY=${GOPROXY:-https://proxy.golang.org}
RUN apt-get update && apt-get install -y musl-tools && \
    cd /workspace && git clone --branch=$JUICEFS_REPO_BRANCH $JUICEFS_REPO_URL && \
    cd juicefs && git checkout $JUICEFS_REPO_REF && \
    bash -c "if [[ ${TARGETARCH} == amd64 ]]; then make juicefs.all && mv juicefs.all juicefs; else make juicefs; fi" && \
    mv juicefs /usr/local/bin/juicefs

# ----------

FROM debian:bookworm-slim
ARG TARGETARCH
COPY --from=binaryimage /usr/local/bin/juicefs /usr/local/bin/juicefs
RUN apt-get update && apt-get install -y wget fuse3 gnupg2 curl procps iputils-ping strace iproute2 net-tools tcpdump lsof openssh-server openssh-client xxd lrzsz
ARG CEPH_RELEASE=
# Optional: install librados from Ceph's own repo (e.g. CEPH_RELEASE=tentacle or squid) instead of Debian
# bookworm's (Pacific 16.2.x). Needed for cephx aes256k keys (CVE-2025-30156) and newer Ceph clusters.
# Empty (default) keeps the Debian packages.
RUN if [ -n "${CEPH_RELEASE}" ]; then \
      wget -qO- https://download.ceph.com/keys/release.asc | gpg --dearmor -o /usr/share/keyrings/ceph.gpg && \
      echo "deb [signed-by=/usr/share/keyrings/ceph.gpg] https://download.ceph.com/debian-${CEPH_RELEASE}/ bookworm main" \
        > /etc/apt/sources.list.d/ceph.list; \
    fi
RUN bash -c "if [[ ${TARGETARCH} == amd64 ]]; then mkdir -p /home/travis/.m2 && \
    wget -O /home/travis/.m2/foundationdb-clients_6.3.23-1_${TARGETARCH}.deb https://github.com/apple/foundationdb/releases/download/6.3.23/foundationdb-clients_6.3.23-1_${TARGETARCH}.deb && \
    dpkg -i /home/travis/.m2/foundationdb-clients_6.3.23-1_${TARGETARCH}.deb && \
    wget -O - https://download.gluster.org/pub/gluster/glusterfs/10/rsa.pub | apt-key add - && \
    echo deb [arch=${TARGETARCH}] https://download.gluster.org/pub/gluster/glusterfs/11/LATEST/Debian/bookworm/${TARGETARCH}/apt bookworm main > /etc/apt/sources.list.d/gluster.list && \
    apt-get update && apt-get install -y uuid-dev libglusterfs-dev glusterfs-common librados2 librados-dev; fi"
RUN mkdir /var/run/sshd

RUN ln -s /usr/local/bin/juicefs /bin/mount.juicefs && /usr/local/bin/juicefs --version
ENV K8S_VERSION v1.14.8
RUN curl -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/${TARGETARCH}/kubectl && chmod +x /usr/local/bin/kubectl
