ARG JENKINS_VERSION
FROM jenkins/jenkins:${JENKINS_VERSION}

ARG NEXUS_DEPLOY_FILE=$JENKINS_HOME/nexus_deploy_file
ARG SONAR_DEPLOY_FILE=$JENKINS_HOME/sonar_deploy_file

COPY devops-docker-tool-1.2.jar /opt/tapd_tool.jar
COPY --chown=jenkins:jenkins ./resource/ref /usr/share/jenkins/ref/
COPY --chown=jenkins:jenkins script /usr/local/bin/

RUN chmod +x /usr/local/bin/start.sh \
&& chmod +x /usr/local/bin/addEnv.sh

USER jenkins

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start.sh"]