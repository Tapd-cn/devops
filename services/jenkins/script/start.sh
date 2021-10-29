#! /bin/bash -e

echo "waiting for nexus starting fully..."
sleep 10s
echo "waiting for sonarqube starting fully..."
sleep 10s

# set jenkins environment variable
source /usr/local/bin/addEnv.sh

# export TAPD_PLUGIN_VERSION=1.5.5.20191209

: "${COPY_REFERENCE_FILE_LOG:="${JENKINS_HOME}/copy_reference_file.log"}"
: "${REF:="/usr/share/jenkins/ref"}"

touch "${COPY_REFERENCE_FILE_LOG}" || { echo "Can not write to ${COPY_REFERENCE_FILE_LOG}. Wrong volume permissions?"; exit 1; }
echo "--- Copying files at $(date)" >> "$COPY_REFERENCE_FILE_LOG"
find "${REF}" \( -type f -o -type l \) -exec bash -c '. /usr/local/bin/jenkins-support; for arg; do copy_reference_file "$arg"; done' _ {} +


#modify demo workspaceId
/bin/bash -c  "sed -i 's/<tapdWorkspaceId>xxx<\/tapdWorkspaceId>/<tapdWorkspaceId>${TAPD_WORKSPACE_ID}<\/tapdWorkspaceId>/' ${JENKINS_HOME}/jobs/DemoPipeline/config.xml"
newJenkinsJobUuid=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c32 )
/bin/bash -c "sed -i 's%<uuid>defaultJobUuid</uuid>%<uuid>${newJenkinsJobUuid}</uuid>%g' ${JENKINS_HOME}/jobs/DemoPipeline/config.xml"

echo "generating new password of Jenkins admin account..."
jenkinsInitPwd=$(tr </dev/urandom -dc 'A-Za-z0-9' | head -c32)
echo $jenkinsInitPwd >${JENKINS_HOME}/jenkinsInitialAdminPassword

echo "save New Jenkins Admin Password"
jenkinsInitPwdHash=$(java -jar /opt/tapd_tool.jar --jenkinsHost=http://localhost:8080 hash-jenkins-password ${jenkinsInitPwd} | sed 's%\$%\\$%g')
/bin/bash -c "sed -i 's%<passwordHash>#jbcrypt:.*</passwordHash>%<passwordHash>#jbcrypt:${jenkinsInitPwdHash}</passwordHash>%g' ${JENKINS_HOME}/users/admin_*/config.xml"


/usr/local/bin/jenkins.sh