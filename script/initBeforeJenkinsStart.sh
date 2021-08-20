echo "waiting for nexus starting fully..."
sleep 20s
echo "waiting for sonarqube starting fully..."
sleep 20s

#modify demo workspaceId
su-exec jenkins /bin/bash -c  "sed -i 's/<tapdWorkspaceId>xxx<\/tapdWorkspaceId>/<tapdWorkspaceId>$TAPD_WORKSPACE_ID<\/tapdWorkspaceId>/' /data/devops_data/jenkins_home/jobs/DemoPipeline/config.xml"
newJenkinsJobUuid=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c32 )
su-exec jenkins /bin/bash -c "sed -i 's%<uuid>defaultJobUuid</uuid>%<uuid>${newJenkinsJobUuid}</uuid>%g' /data/devops_data/jenkins_home/jobs/DemoPipeline/config.xml"

echo "generating new password of Jenkins admin account..."
jenkinsInitPwd=$(tr </dev/urandom -dc 'A-Za-z0-9' | head -c32)
echo $jenkinsInitPwd >/data/devops_data/secrets/jenkinsInitialAdminPassword

echo "save New Jenkins Admin Password"
jenkinsInitPwdHash=$(java -jar /opt/tapd_tool.jar hash-jenkins-password ${jenkinsInitPwd} | sed 's%\$%\\$%g')
su-exec jenkins /bin/bash -c "sed -i 's%<passwordHash>#jbcrypt:.*</passwordHash>%<passwordHash>#jbcrypt:${jenkinsInitPwdHash}</passwordHash>%g' ${JENKINS_HOME}/users/admin_*/config.xml"