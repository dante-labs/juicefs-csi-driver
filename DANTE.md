# dante-labs fork

Branch `tentacle-librados`: `docker/ce.juicefs.Dockerfile` gains an optional `CEPH_RELEASE` build arg that installs
librados from download.ceph.com (`debian-<release>`) instead of Debian bookworm's Pacific 16.2.x, in both the
build and runtime stages. Needed for cephx `aes256k` keys (CVE-2025-30156) and newer Ceph clusters; empty keeps
upstream behaviour. Workflow `dante-mount-image` builds JuiceFS CE (default v1.4.1) with `CEPH_RELEASE=tentacle`,
verifies it, and pushes `ghcr.io/dante-labs/juicefs-mount:ce-<juicefs>-ceph<librados>`.
Intended to be offered upstream (juicedata/juicefs#6525 is related).
