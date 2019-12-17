#! /bin/bash -e

: "${JENKINS_WAR:="/usr/share/jenkins/jenkins.war"}"
: "${JENKINS_HOME:="/data/devops_data/jenkins_home"}"
: "${INIT_FILE:="/data/devops_data/init_file"}"

export TAPD_PLUGIN_VERSION=1.5.5.20191209

touch "${COPY_REFERENCE_FILE_LOG}" || { echo "Can not write to ${COPY_REFERENCE_FILE_LOG}. Wrong volume permissions?"; exit 1; }
echo "--- Copying files at $(date)" >> "$COPY_REFERENCE_FILE_LOG"
find /usr/share/jenkins/ref/ \( -type f -o -type l \) -exec bash -c '. /usr/local/bin/jenkins-support; for arg; do copy_reference_file "$arg"; done' _ {} +

# set proxy
if [[ $proxyHost && $proxyPort ]]; then
  if [ -z $proxyProtocol ]; then
    : "${proxyProtocol:="http"}"
  fi
  sed -i "s%.*</proxies>%<proxy><id>optional</id><active>true</active><protocol>${proxyProtocol}</protocol><username>${proxyUser}</username><password>${proxyPass}</password><host>${proxyHost}</host><port>${proxyPort}</port><nonProxyHosts>${noProxy}</nonProxyHosts></proxy></proxies>%"  /usr/local/maven/conf/settings.xml
  echo "export http_proxy=${proxyProtocol}://${proxyHost}:${proxyPort}" >> /etc/profile
  echo "export https_proxy=${proxyProtocol}://${proxyHost}:${proxyPort}" >> /etc/profile
  echo "export no_proxy=${noProxy}" >> /etc/profile  
  source /etc/profile
fi

#if max < 262144 set it
#sysctl -w vm.max_map_count=262144

#start nexus
nexusStartCmd="export RUN_AS_USER=nexus && export PATH=$PATH:$JAVA_HOME/bin && /usr/share/nexus/nexus-2.14.12-02/bin/nexus start"
su - nexus -c "$nexusStartCmd"

#start sonarqube
sonarqubeStartCmd="export PATH=$PATH:$JAVA_HOME/bin && /usr/share/sonarqube/sonarqube-7.8/bin/linux-x86-64/sonar.sh start"
su - sonarqube -c "$sonarqubeStartCmd"

#touch init log
mkdir -p /data/logs/
if [ ! -f /data/logs/init.log ]; then
  touch /data/logs/init.log
fi

/usr/local/bin/check.sh

#init before jenkins start
if [ ! -f "$INIT_FILE" ]; then
  source /usr/local/bin/initBeforeJenkinsStart.sh
  echo "init before jenkins start";
fi

#start jenkins
echo "start jenkins ...";
jenkinsStartCmd="source /etc/profile && mkdir -p $JENKINS_HOME/logs && export PATH=$PATH:$JAVA_HOME/bin && export JENKINS_HOME=$JENKINS_HOME && nohup java -Djava.net.useSystemProxies=true -jar /usr/share/jenkins/jenkins.war > $JENKINS_HOME/logs/run.log 2>&1 & "
su - jenkins -c "$jenkinsStartCmd"
echo "jenkins is started";


#init 
if [ ! -f "$INIT_FILE" ]; then
  source /usr/local/bin/init.sh > /data/logs/init.log &
fi

#exec "$@"
#tail -f ${JENKINS_HOME}/logs/run.log
tail -f /data/logs/init.log

