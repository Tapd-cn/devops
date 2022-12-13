#! /bin/bash -e

: "${JENKINS_WAR:="/usr/share/jenkins/jenkins.war"}"
: "${JENKINS_HOME:="/data/devops_data/jenkins_home"}"
: "${NEXUS_HOME:="/data/devops_data/nexus_home"}"
: "${SONARQUBE_HOME:="/data/devops_data/sonarqube_home"}"
: "${INIT_FILE:="/data/devops_data/init_file"}"
: "${COPY_REFERENCE_FILE_LOG:="${JENKINS_HOME}/copy_reference_file.log"}"
: "${REF:="/usr/share/jenkins/ref"}"

#if max < 262144 set it
#sysctl -w vm.max_map_count=262144

# touch init log
mkdir -p /data/secrets/
mkdir -p /data/logs/
if [ ! -f /data/logs/init.log ]; then
  touch /data/logs/init.log
fi

/usr/local/bin/check.sh

#init 
if [ ! -f "$INIT_FILE" ]; then
  source /usr/local/bin/init.sh >> /data/logs/init.log &
fi

# exec "$@"
# su - jenkins -c "tail -f ${JENKINS_HOME}/logs/run.log"
tail -f /data/logs/init.log