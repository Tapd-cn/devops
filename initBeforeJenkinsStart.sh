echo "waiting for nexus starting fully..."
sleep 10s
echo "waiting for sonarqube starting fully..."
sleep 10s

echo $JENKINS_HOME;

tapdAuthPre="https://www.tapd.cn/devops/auth/index/"

tapdAuthInfo=$(curl -s $tapdAuthPre$token)
if [ -z $tapdAuthInfo ] || [ $tapdAuthInfo == "error" ]; then
    echo -e "\033[31merror code:301\nerror msg:TAPD auth faild\033[0m"
    exit 1
fi
tapdAuthInfoArray=(${tapdAuthInfo//|/ })

source /usr/local/bin/addEnv.sh

#modify demo workspaceId
sed -i "s/<tapdWorkspaceId>xxx<\/tapdWorkspaceId>/<tapdWorkspaceId>$TAPD_WORKSPACE_ID<\/tapdWorkspaceId>/" /data/devops_data/jenkins_home/jobs/DemoPipeline/config.xml
newJenkinsJobUuid=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c32 )
sed -i "s%<uuid>defaultJobUuid</uuid>%<uuid>${newJenkinsJobUuid}</uuid>%g" /data/devops_data/jenkins_home/jobs/DemoPipeline/config.xml

echo "generating new password of Jenkins admin account..."
jenkinsInitPwd=$(tr </dev/urandom -dc 'A-Za-z0-9' | head -c32)
echo $jenkinsInitPwd >${JENKINS_HOME}/secrets/initialAdminPassword

echo "save New Jenkins Admin Password"
jenkinsInitPwdHash=$(java -jar /opt/tapd_tool.jar hash-jenkins-password ${jenkinsInitPwd} | sed 's%\$%\\$%g')
sed -i "s%<passwordHash>#jbcrypt:.*</passwordHash>%<passwordHash>#jbcrypt:${jenkinsInitPwdHash}</passwordHash>%g" ${JENKINS_HOME}/users/admin_*/config.xml
