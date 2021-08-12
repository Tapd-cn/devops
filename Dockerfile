ARG JENKINS_IMAGE=jenkins/jenkins:2.224
ARG SONARQUBE_IMAGE=sonarqube:8.9.0-community
ARG NEXUS_IMAGE=sonatype/nexus3:3.26.1
ARG JDK_IMAGE=ccr.ccs.tencentyun.com/tapd-devops/tencentkona11:1.0.0

FROM ${JENKINS_IMAGE} AS JENKINS

FROM ${SONARQUBE_IMAGE} AS SONARQUBE

FROM ${NEXUS_IMAGE} AS NEXUS

FROM ${JDK_IMAGE}

RUN echo -e https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.12/main/ > /etc/apk/repositories \
  && echo -e https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.12/community/ >> /etc/apk/repositories \
  && apk update \
  && apk add --no-cache \
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
  unzip

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

ARG jenkins_port=8080
ARG jenkins_agent_port=50000
ARG nexus_port=8081
ARG sonarqube_port=9000

ARG BASE_DATA_HOME=/data/devops_data
ARG JENKINS_HOME=$BASE_DATA_HOME/jenkins_home
ARG SONATYPE_DIR=$BASE_DATA_HOME/nexus_home
ARG SONARQUBE_HOME=$BASE_DATA_HOME/sonarqube_home
ARG NEXUS_HOME=$SONATYPE_DIR/nexus
ARG INIT_FILE=$BASE_DATA_HOME/init_file

ENV JENKINS_HOME=$JENKINS_HOME \
    JENKINS_SLAVE_AGENT_PORT=${jenkins_agent_port} \
    JENKINS_UC=https://updates.jenkins.io \
    JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental \
    JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals \
    COPY_REFERENCE_FILE_LOG=$JENKINS_HOME/copy_reference_file.log

# Install git lfs per https://github.com/git-lfs/git-lfs#from-binary
# Avoid JENKINS-59569 - git LFS 2.7.1 fails clone with reference repository
ARG GIT_LFS_VERSION=v2.11.0
ENV GIT_LFS_VERSION=$GIT_LFS_VERSION
RUN curl -fsSLO https://github.com/git-lfs/git-lfs/releases/download/${GIT_LFS_VERSION}/git-lfs-linux-$(dpkg --print-architecture | tr '-' ' '| awk '{print $NF}')-${GIT_LFS_VERSION}.tar.gz \
  && curl -fsSLO https://github.com/git-lfs/git-lfs/releases/download/${GIT_LFS_VERSION}/sha256sums.asc \
  && curl -L https://github.com/bk2204.gpg | gpg --no-tty --import \
  && gpg -d sha256sums.asc | grep git-lfs-linux-$(dpkg --print-architecture | tr '-' ' '| awk '{print $NF}')-${GIT_LFS_VERSION}.tar.gz | sha256sum -c \
  && tar -zvxf git-lfs-linux-$(dpkg --print-architecture | tr '-' ' '| awk '{print $NF}')-${GIT_LFS_VERSION}.tar.gz git-lfs \
  && mv git-lfs /usr/bin/ \
  && rm -rf git-lfs-linux-$(dpkg --print-architecture | tr '-' ' '| awk '{print $NF}')-${GIT_LFS_VERSION}.tar.gz sha256sums.asc /root/.gnupg \
  && git lfs install

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN mkdir -p $JENKINS_HOME \
  && chown ${uid}:${gid} $JENKINS_HOME \
  && addgroup -g ${gid} ${group} \
  && adduser -h "$JENKINS_HOME" -u ${uid} -G ${group} -s /bin/bash -D ${user} \
  && mkdir -p /usr/share/jenkins/ref/init.groovy.d \
  && chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE ${jenkins_port}
# will be used by attached agents:
EXPOSE ${jenkins_agent_port}

# add custom config for all in one devops
USER root

ENV INIT_FILE=${INIT_FILE} \
    SONARQUBE_HOME=${SONARQUBE_HOME} \
    SONATYPE_DIR=${SONATYPE_DIR} \
    NEXUS_HOME=${NEXUS_HOME} \
    JENKINS_SCHEME=http \
    JENKINS_PORT=8080 \
    JENKINS_VERSION=2.224 \
    SONAR_SCHEME=http \
    SONAR_PORT=9000 \
    SONAR_VERSION=8.9.0.43852 \
    NEXUS_SCHEME=http \
    NEXUS_PORT=8081 \
    NEXUS_DATA=$SONATYPE_DIR/nexus-data \
    NEXUS_CONTEXT=''  \
    SONATYPE_WORK=$SONATYPE_DIR/sonatype-work \
    TAPD_PLUGIN_VERSION=1.6.2.20210722.1

# download java8 for nexus
WORKDIR /user/share/jvm
RUN  curl -o TencentKona8.tar.gz https://devops-1251542635.cos.ap-guangzhou.myqcloud.com/TencentKona8.0.0-internal_jdk_linux-x86_64_8u232.tar.gz \
  && tar -zxf TencentKona8.tar.gz \
  && rm TencentKona8.tar.gz

ENV INSTALL4J_JAVA_HOME=/user/share/jvm/TencentKona-8.0.0-232 \
    INSTALL4J_ADD_VM_PARAMS="-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs"

RUN  mkdir -p ${SONARQUBE_HOME} \
  && mkdir -p ${SONATYPE_DIR} \
  && mkdir -p ${NEXUS_DATA} \
  && addgroup sonarqube \
  && adduser -G sonarqube -D sonarqube \
  && addgroup nexus \
  && adduser -G nexus -D nexus

COPY --from=JENKINS --chown=jenkins:jenkins /usr/share/jenkins/jenkins.war /usr/share/jenkins/jenkins.war
COPY --from=JENKINS --chown=jenkins:jenkins /usr/local/bin/jenkins-support /usr/local/bin/jenkins-support
COPY --from=SONARQUBE --chown=sonarqube:sonarqube /opt/sonarqube ${SONARQUBE_HOME}
COPY --from=NEXUS --chown=nexus:nexus /opt/sonatype ${SONATYPE_DIR}
COPY --from=NEXUS --chown=nexus:nexus /nexus-data ${NEXUS_DATA}
COPY devops-docker-tool-1.1.jar /opt/tapd_tool.jar
COPY --chown=root:root script /usr/local/bin/
COPY --chown=jenkins:jenkins resource/jenkins/ref /usr/share/jenkins/ref/

RUN chmod +x /usr/local/bin/*.sh \
  && ln -snf $NEXUS_DATA  $SONATYPE_WORK/nexus3 \
  && chown -R jenkins:jenkins ${JENKINS_HOME} \
  && chown -R sonarqube:sonarqube ${SONARQUBE_HOME} \
  && chown -R nexus:nexus ${SONATYPE_DIR}

EXPOSE $SONAR_PORT
EXPOSE $NEXUS_PORT

# home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME $BASE_DATA_HOME
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start.sh"]