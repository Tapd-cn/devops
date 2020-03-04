FROM terrysxu/jenkins:latest

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

ARG nexus_port=8081
ARG sonarqube_port=9000

ARG BASE_DATA_HOME=/data/devops_data
ARG NEXUS_HOME=$BASE_DATA_HOME/nexus_home
ARG SONARQUBE_HOME=$BASE_DATA_HOME/sonarqube_home
ARG INIT_FILE=$BASE_DATA_HOME/init_file

USER root

ENV INIT_FILE ${INIT_FILE}
ENV SONARQUBE_HOME ${SONARQUBE_HOME}
ENV NEXUS_HOME ${NEXUS_HOME}

ENV JENKINS_SCHEME http
ENV JENKINS_PORT 8080

ENV SONAR_SCHEME http
ENV SONAR_PORT 9000

ENV NEXUS_SCHEME http
ENV NEXUS_PORT 8081

RUN curl -fsSLO https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.zip \
  && unzip apache-maven-3.6.3-bin.zip \
  && mv -f apache-maven-3.6.3 /usr/local/maven \
  && rm -f apache-maven-3.6.3-bin.zip \
  && ln -s /usr/local/maven/bin/mvn /usr/local/bin/mvn \
  && ln -s /usr/local/maven/bin/mvnDebug /usr/local/bin/mvnDebug \
  && curl -fsSLO https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.2.0.1873-linux.zip \
  && unzip sonar-scanner-cli-4.2.0.1873-linux.zip \
  && mv -f sonar-scanner-4.2.0.1873-linux /usr/local/sonar-scanner \
  && rm -f sonar-scanner-cli-4.2.0.1873-linux.zip 

COPY start.sh /usr/local/bin/start.sh
COPY init.sh /usr/local/bin/init.sh
COPY addEnv.sh /usr/local/bin/addEnv.sh
COPY check.sh /usr/local/bin/check.sh
COPY check.sh /usr/local/bin/checkSystem.sh
COPY initBeforeJenkinsStart.sh /usr/local/bin/initBeforeJenkinsStart.sh
COPY TapdDevopsInitTool-1.0.jar /opt/tapd_tool.jar
COPY nexus.properties /usr/share/nexus/nexus.properties
COPY sonar.properties /usr/share/sonarqube/sonar.properties

RUN groupadd sonarqube \
  && useradd sonarqube -g sonarqube \
  && groupadd nexus \
  && useradd nexus -g nexus \
  && mkdir -p ${SONARQUBE_HOME}/data \	
  && mkdir -p /usr/share/sonarqube \
  && mkdir -p ${NEXUS_HOME} \
  && mkdir -p /usr/share/nexus \  
  && mkdir -p /tmp/package \
  \
  && cd /tmp/package \
  && wget https://test-1251542635.cos.ap-guangzhou.myqcloud.com/devops-default-conf.tar.gz >/dev/null 2>&1  \
  && tar -zxf devops-default-conf.tar.gz \
  && mv -f sonarqube-7.8 /usr/share/sonarqube  \
  && mv -f /usr/share/sonarqube/sonar.properties /usr/share/sonarqube/sonarqube-7.8/conf/sonar.properties \
  && mv -f nexus/* /usr/share/nexus/ \
  && mv -f /usr/share/nexus/nexus.properties /usr/share/nexus/nexus-2.14.12-02/conf/nexus.properties \
  && mv -f default_data/jenkins_data/* $JENKINS_HOME/ \
  \
  && mv -f /usr/share/nexus/sonatype-work  $NEXUS_HOME/ \
  \
  && rm -rf /usr/share/nexus/sonatype-work \
  && rm -rf /tmp/package \
  \
  && chown -R sonarqube:sonarqube /usr/share/sonarqube \
  && chmod +x /usr/share/sonarqube/sonarqube-7.8  \
	&& chmod +x /usr/share/nexus/nexus-2.14.12-02/bin/nexus \
  && chown -R nexus:nexus ${NEXUS_HOME} \
  && chown -R nexus:nexus /usr/share/nexus \
  && chown -R jenkins:jenkins ${JENKINS_HOME} \
  && chown -R sonarqube:sonarqube ${SONARQUBE_HOME} \
  \
  && chmod +x /usr/local/bin/start.sh \
  && chmod +x /usr/local/bin/init.sh \
  && chmod +x /usr/local/bin/addEnv.sh \
  && chmod +x /usr/local/bin/check.sh \
  && chmod +x /usr/local/bin/checkSystem.sh \
  && chmod +x /usr/local/bin/initBeforeJenkinsStart.sh \
  && ln -s $JAVA_HOME/bin/java /usr/local/bin/java

VOLUME $BASE_DATA_HOME
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start.sh"]
