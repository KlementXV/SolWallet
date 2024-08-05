FROM rockylinux:9.3 AS builder

ARG SOLANA_VERSION

RUN mkdir -p /mnt/rootfs && \
    dnf install -y epel-release && \
    dnf -y --releasever=9 --installroot=/mnt/rootfs --setopt=install_weak_deps=false --nodocs install \
    glibc-minimal-langpack \
    coreutils-single \
    ncurses \
    curl \
    qrencode \
    systemd-libs && \
    dnf clean all && \
    rm -rf /var/cache/dnf && \
    curl -sSfL https://release.solana.com/v1.18.20/install | bash

FROM scratch

COPY --from=builder /mnt/rootfs/ /
RUN mkdir /soluser /wallets && \
    groupadd -r -g 1000 soluser && \
    useradd -u 1000 -g soluser -d /soluser soluser && \
    chown soluser: /soluser /wallets
COPY --from=builder --chown=soluser:soluser --chmod=500 /root/.local/share/solana/install/active_release/bin/solana /usr/local/bin/solana
COPY --from=builder  --chown=soluser:soluser --chmod=500 /root/.local/share/solana/install/active_release/bin/solana-keygen /usr/local/bin/solana-keygen
COPY --chown=soluser:soluser --chmod=500 entrypoint.sh /usr/local/bin/entrypoint.sh

USER soluser

WORKDIR /soluser

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]