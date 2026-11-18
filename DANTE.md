# dante-labs fork

Branch `tentacle-librados`: `docker/ce.juicefs.Dockerfile` gains an optional `CEPH_RELEASE` build arg that installs
librados from download.ceph.com (`debian-<release>`) instead of Debian bookworm's Pacific 16.2.x, in both the
build and runtime stages. Needed for cephx `aes256k` keys (CVE-2025-30156) and newer Ceph clusters; empty keeps
upstream behaviour. Workflow `dante-mount-image` builds JuiceFS CE (default v1.4.1) with `CEPH_RELEASE=tentacle`,
verifies it, and pushes `ghcr.io/dante-labs/juicefs-mount:ce-<juicefs>-ceph<librados>`.
Intended to be offered upstream (juicedata/juicefs#6525 is related).

`docker/dante-csi.Dockerfile` + workflow `dante-csi-image`: the upstream `juicedata/juicefs-csi-driver` image
(default v0.33.3) with `apt-get upgrade` applied, because upstream ships a stale bookworm base (openssl, gnutls,
perl criticals). CI fails if any fixable CRITICAL OS CVE remains, then pushes
`ghcr.io/dante-labs/juicefs-csi-driver:<tag>-patched[-<sha>]`. Drop it once upstream rebuilds on a current base.
