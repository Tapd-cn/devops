# Extended from https://github.com/jenkinsci/docker/blob/master/README.md
FROM jenkins/jenkins:lts-alpine

# Skip setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Get plugins
# Strangely, the defaut JENKINS_UC url does not work for the install-plugins.sh script?
#ENV JENKINS_UC="http://updates.jenkins-ci.org"
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY TapdPipeLine.jpi /usr/share/jenkins/ref/plugins/

USER root
RUN chown -R jenkins:jenkins /usr/share/jenkins

USER jenkins
RUN jenkins-plugin-cli --verbose --war "/usr/share/jenkins/jenkins.war" --plugin-file "/usr/share/jenkins/ref/plugins.txt"

# Add groovy script to Jenkins hook
#COPY --chown=jenkins:jenkins init.groovy.d/ /var/jenkins_home/init.groovy.d/
COPY init.groovy.d/ /var/jenkins_home/init.groovy.d/