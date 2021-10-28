FROM mirrors.tencent.com/tjdk/tencentkona11

ARG TZ

COPY ./devops-docker-tool-1.2.jar /opt/tapd_tool.jar
COPY --chown=root:root script /usr/local/bin/

RUN apk add --no-cache \
  su-exec \
  bash \
  coreutils \
  curl \
  git \
  dpkg \
  gnupg \
  tar \
  openssh-client \
  tini \
  ttf-dejavu \
  tzdata \
  unzip \
  && chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start.sh"]