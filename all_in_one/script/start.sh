#! /bin/bash -e

: "${JENKINS_WAR:="/usr/share/jenkins/jenkins.war"}"
: "${JENKINS_HOME:="/data/devops_data/jenkins_home"}"
: "${NEXUS_HOME:="/data/devops_data/nexus_home"}"
: "${SONARQUBE_HOME:="/data/devops_data/sonarqube_home"}"
: "${INIT_FILE:="/data/devops_data/init_file"}"
: "${COPY_REFERENCE_FILE_LOG:="${JENKINS_HOME}/copy_reference_file.log"}"
: "${REF:="/usr/share/jenkins/ref"}"

# export TAPD_PLUGIN_VERSION=1.5.5.20191209

su-exec jenkins touch "${COPY_REFERENCE_FILE_LOG}" || { echo "Can not write to ${COPY_REFERENCE_FILE_LOG}. Wrong volume permissions?"; exit 1; }
echo "--- Copying files at $(date)" >> "$COPY_REFERENCE_FILE_LOG"
su-exec jenkins find "${REF}" \( -type f -o -type l \) -exec bash -c '. /usr/local/bin/jenkins-support; for arg; do copy_reference_file "$arg"; done' _ {} +

#if max < 262144 set it
#sysctl -w vm.max_map_count=262144

# rm nexus deploy file before nexus starting
rm -f $NEXUS_DEPLOY_FILE
# start nexus
su-exec nexus /bin/bash -c "export RUN_AS_USER=nexus && cd $NEXUS_HOME && nohup bin/nexus run >/dev/null 2>&1 &"

# rm sonar deploy file before sonar starting
rm -f $SONAR_DEPLOY_FILE
#start sonarqube
su-exec sonarqube /bin/bash -c "cd $SONARQUBE_HOME && nohup $SONARQUBE_HOME/bin/run.sh $SONARQUBE_HOME/bin/sonar.sh >/dev/null 2>&1 &"

# touch init log
mkdir -p /data/devops_data/secrets/
mkdir -p /data/devops_data/logs/
if [ ! -f /data/devops_data/logs/init.log ]; then
  touch /data/devops_data/logs/init.log
fi

/usr/local/bin/check.sh

# set jenkins environment variable
source /usr/local/bin/addEnv.sh

# init before jenkins start
if [ ! -f "$INIT_FILE" ]; then
  source /usr/local/bin/initBeforeJenkinsStart.sh > /data/devops_data/logs/init.log
  echo "init before jenkins start";
fi

#start jenkins
echo "start jenkins ...";
# rm jenkins deploy file before jenkins starting
rm -f $JENKINS_DEPLOY_FILE
su-exec jenkins /bin/bash -c "mkdir -p $JENKINS_HOME/logs && nohup java -Djava.net.useSystemProxies=true -Dfile.encoding=UTF-8 -jar $JENKINS_WAR > $JENKINS_HOME/logs/run.log 2>&1 &"
echo "jenkins is started";

#init 
if [ ! -f "$INIT_FILE" ]; then
  source /usr/local/bin/init.sh >> /data/devops_data/logs/init.log &
fi

# exec "$@"
# su - jenkins -c "tail -f ${JENKINS_HOME}/logs/run.log"
tail -f -n +1 /data/devops_data/logs/init.log