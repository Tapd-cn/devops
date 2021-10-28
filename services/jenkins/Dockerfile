ARG JENKINS_VERSION
FROM jenkinsci/blueocean:${JENKINS_VERSION}

ARG TZ
ARG GIT_LFS_VERSION

COPY --chown=jenkins:jenkins ./resource/ref /usr/share/jenkins/ref/

RUN apk --no-cache add tzdata \
    && cp "/usr/share/zoneinfo/$TZ" /etc/localtime \
    && echo "$TZ" > /etc/timezone \
    && curl -fsSLO https://github.com/git-lfs/git-lfs/releases/download/${GIT_LFS_VERSION}/git-lfs-linux-$(dpkg --print-architecture | tr '-' ' '| awk '{print $NF}')-${GIT_LFS_VERSION}.tar.gz \
    && curl -fsSLO https://github.com/git-lfs/git-lfs/releases/download/${GIT_LFS_VERSION}/sha256sums.asc \
    && curl -L https://github.com/bk2204.gpg | gpg --no-tty --import \
    && gpg -d sha256sums.asc | grep git-lfs-linux-$(dpkg --print-architecture | tr '-' ' '| awk '{print $NF}')-${GIT_LFS_VERSION}.tar.gz | sha256sum -c \
    && tar -zvxf git-lfs-linux-$(dpkg --print-architecture | tr '-' ' '| awk '{print $NF}')-${GIT_LFS_VERSION}.tar.gz git-lfs \
    && mv git-lfs /usr/bin/ \
    && rm -rf git-lfs-linux-$(dpkg --print-architecture | tr '-' ' '| awk '{print $NF}')-${GIT_LFS_VERSION}.tar.gz sha256sums.asc /root/.gnupg \
    && git lfs install

USER ${user}

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start.sh"]