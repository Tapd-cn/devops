#! /bin/bash -e

echo "waiting for jenkins starting fully..."
sleep 15s

# set jenkins environment variable
source /usr/local/bin/addEnv.sh

# set jenkins environment variable end
echo "Waiting for initializing data... This may take some time ..."
sleep 25s

oldJenkinsPwd=$(cat ${JENKINS_HOME}/secrets/initialAdminPassword)

su - sonarqube -c "export PATH=$PATH:$JAVA_HOME/bin && /usr/share/sonarqube/sonarqube-7.8/bin/linux-x86-64/sonar.sh status"

# generate url
jenkinsCrumbTokenURL="$JENKINS_SCHEME://localhost:8080/crumbIssuer/api/json"
jenkinsCreateCredentialsURL="$JENKINS_SCHEME://localhost:8080/credentials/store/system/domain/_/createCredentials"
jenkinsAddNexusCfgURL="$JENKINS_SCHEME://localhost:8080/tapd-devops-init/nexus"
jenkinsAddSonarqubeCfgURL="$JENKINS_SCHEME://localhost:8080/tapd-devops-init/sonar"
jenkinsDemoPipelineBuildURL="$JENKINS_SCHEME://localhost:8080/job/DemoPipeline/build"
nexusChangePwdURL="$NEXUS_SCHEME://localhost:8081/nexus/service/local/users_changepw"
sonarqubeRevokeTokenURL="$SONAR_SCHEME://localhost:9000/api/user_tokens/revoke"
sonarqubeGenerateTokenURL="$SONAR_SCHEME://localhost:9000/api/user_tokens/generate"
sonarqubeChangePwdURL="$SONAR_SCHEME://localhost:9000/api/users/change_password"

echo "generating new password of Nexus admin account...";
nexusInitPwd=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c32 )
echo "save New Nexus Admin Password";
curl -slL -u admin:admin123 -X POST -d '{"data": {"oldPassword":"admin123", "userId":admin, "newPassword":"'"${nexusInitPwd}"'"}}' -H "Content-Type: application/json; charset=UTF-8" $nexusChangePwdURL

echo "generating credential for nexus...";
crumbToken=$(curl -slL -u "admin:${oldJenkinsPwd}" $jenkinsCrumbTokenURL | sed -n -e 's/"//gp' | sed -n -e 's/,/\n/gp'| grep crumb: | awk -F ':' '{print $2}')
curl -s -X POST -u "admin:${oldJenkinsPwd}"  -H "Jenkins-Crumb:${crumbToken}" $jenkinsCreateCredentialsURL --data-urlencode 'json={"":"0","credentials":{"scope":"GLOBAL","id":"DevOpsNexusPassword","username":"admin","password":"'"${nexusInitPwd}"'","description":"DevOpsNexusPassword","$class":"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"}}'

sleep 5;
echo "adding Nexus configuration to jenkins ...";
crumbToken=$(curl -slL -u "admin:${oldJenkinsPwd}" $jenkinsCrumbTokenURL | sed -n -e 's/"//gp' | sed -n -e 's/,/\n/gp'| grep crumb: | awk -F ':' '{print $2}')
curl -slL -X POST -u "admin:${oldJenkinsPwd}" -H "Jenkins-Crumb:${crumbToken}" $jenkinsAddNexusCfgURL --data-urlencode "id=DevOpsNexus" --data-urlencode "displayName=DevOpsNexus" --data-urlencode "serverUrl=${NEXUS_SCHEME}://${HOST}:${NEXUS_PORT}/nexus" --data-urlencode "credentialsId=DevOpsNexusPassword"
echo "configuring tapd plugin...";
java -jar /opt/tapd_tool.jar config-tapd --username="admin" --password="${oldJenkinsPwd}"

echo "generating SonarQube token...";
curl -slL -u admin:admin -X POST -d "login=admin&name=jenkins" $sonarqubeRevokeTokenURL
sonarQubeServerToken=$(curl -slL --basic -u admin:admin -X POST -d "login=admin&name=jenkins" $sonarqubeGenerateTokenURL | sed -n -e 's/"//gp' |sed -n -e 's/,/\n/gp' | grep token|awk -F ':' '{print $2}')

echo "adding SonarQube configuration to jenkins...";
crumbToken=$(curl -slL -u "admin:${oldJenkinsPwd}" $jenkinsCrumbTokenURL | sed -n -e 's/"//gp' | sed -n -e 's/,/\n/gp'| grep crumb: | awk -F ':' '{print $2}')
curl -slL -X POST -u "admin:${oldJenkinsPwd}" -H "Jenkins-Crumb:${crumbToken}" $jenkinsAddSonarqubeCfgURL  --data-urlencode "name=DevOpsSonarQube" --data-urlencode  "serverUrl=${SONAR_SCHEME}://${HOST}:${SONAR_PORT}" --data-urlencode "serverAuthenticationToken=${sonarQubeServerToken}"

echo "generating new password of Sonarqube admin account...";
sonarqubeInitPwd=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c32 )
echo "save New Sonarqube Admin Password";
curl -slL -u admin:admin -X POST -d "login=admin&password=${sonarqubeInitPwd}&previousPassword=admin" $sonarqubeChangePwdURL

echo "save DemoPiepline";
currentTime=$(date +%s000)
demoPipelineConfig=$(cat $JENKINS_HOME/jobs/DemoPipeline/config.xml | sed 's%"%\\"%g') 
signature=$(echo -n "10${JENKINS_NAME}${JENKINS_VERSION}OP_CONFIG_UPDATE_JOB_CONFIG${TAPD_PLUGIN_VERSION}${TAPD_SECRET_TOKEN}${currentTime}" | md5sum | cut -d ' ' -f1)
echo "{\"currentTime\":${currentTime},\"data\":{\"type\":\"pipeline\",\"job_name\":\"DemoPipeline\",\"job_description\":\"这是一条Demo流水线，包含构建对象、代码检查、自动化测试、构建制品等环节。如不需使用，可以在Jenkins中删除当前Pipeline。\",\"next_build_number\":\"1\",\"build_config\":\"${demoPipelineConfig}\",\"current_workspace_id\":\"${TAPD_WORKSPACE_ID}\",\"jenkins_config_key\":\"${newJenkinsJobUuid}\",\"pipeline_name\":\"\",\"triggersize\":\"0\",\"job_relations\":\"\"},\"jenkinsName\":\"${JENKINS_NAME}\",\"jenkinsVersion\":\"${JENKINS_VERSION}\",\"opType\":\"OP_CONFIG_UPDATE_JOB_CONFIG\",\"pluginVersion\":\"${TAPD_PLUGIN_VERSION}\",\"secretToken\":\"${TAPD_SECRET_TOKEN}\",\"signature\":\"${signature}\",\"status\":\"1\"}" > tmp.json
curl -slL -X POST -d "@tmp.json" -H "Content-type: application/json" ${TAPD_WEB_HOOK_URL}?HTTP_X_JENKINS_EVENT=HTTP_X_JENKINS_EVENT

echo -e "\ntrigger build"
crumbToken=$(curl -slL -u "admin:${oldJenkinsPwd}" $jenkinsCrumbTokenURL | sed -n -e 's/"//gp' | sed -n -e 's/,/\n/gp'| grep crumb: | awk -F ':' '{print $2}')
curl -slL -X POST -u "admin:${oldJenkinsPwd}" -H "Jenkins-Crumb:${crumbToken}" $jenkinsDemoPipelineBuildURL

echo -e "Jenkins Password for admin is \n********************************\n${oldJenkinsPwd} \n********************************\nyou also can find it in ${JENKINS_HOME}/secrets/initialAdminPassword\n"
echo -e "Nexus Password for admin is \n********************************\n${nexusInitPwd} \n******************************** \n"
echo -e "Sonarqube Password for admin is \n********************************\n${sonarqubeInitPwd} \n******************************** \n"

echo -e "\n\nInitializing Finished\n\n"

touch $INIT_FILE