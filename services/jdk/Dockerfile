FROM mirrors.tencent.com/tjdk/tencentkona11

ARG TZ
ARG BASE_DATA_HOME

COPY ../../devops-docker-tool-1.2.jar /opt/tapd_tool.jar
COPY --chown=root:root script /usr/local/bin/

WORKDIR /user/share/jvm
RUN  curl -o TencentKona8.tar.gz http://bia.oa.com/mirror/8/0/0/linux-x86_64/b1/TencentKona8.0.0-internal_jdk_linux-x86_64_8u232.tar.gz \
  && tar -zxf TencentKona8.tar.gz \
  && rm TencentKona8.tar.gz

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

VOLUME ${BASE_DATA_HOME}
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start.sh"]