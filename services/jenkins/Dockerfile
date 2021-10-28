ARG JENKINS_VERSION
FROM jenkins/jenkins:${JENKINS_VERSION}


COPY ../../devops-docker-tool-1.2.jar /opt/tapd_tool.jar
COPY --chown=jenkins:jenkins ./resource/ref /usr/share/jenkins/ref/
COPY --chown=jenkins:jenkins script /usr/local/bin/

RUN chmod +x /usr/local/bin/start.sh \
&& chmod +x /usr/local/bin/addEnv.sh

USER jenkins

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start.sh"]