#! /bin/bash -e

# set jenkins environment variable
source /usr/local/bin/addEnv.sh

# set jenkins environment variable end
echo "Waiting for initializing data... This may take some time ..."
sleep 30s

JenkinsPwd=$(cat ${JENKINS_HOME}/jenkinsInitialAdminPassword)
oldNexusPwd=$(cat $NEXUS_DATA/admin.password)

# generate url
jenkinsCrumbTokenURL=$JENKINS_SCHEME://jenkins:$JENKINS_PORT/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\)
jenkinsCreateAPITokenURL=$JENKINS_SCHEME://jenkins:$JENKINS_PORT/user/admin/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken
jenkinsCreateCredentialsURL=$JENKINS_SCHEME://jenkins:$JENKINS_PORT/credentials/store/system/domain/_/createCredentials
jenkinsAddNexusCfgURL=$JENKINS_SCHEME://jenkins:$JENKINS_PORT/tapd-devops-init/nexus
jenkinsAddSonarqubeCfgURL=$JENKINS_SCHEME://jenkins:$JENKINS_PORT/tapd-devops-init/sonar
jenkinsDemoPipelineBuildURL=$JENKINS_SCHEME://jenkins:$JENKINS_PORT/job/DemoPipeline/tapdbuild/build
nexusChangePwdURL=$NEXUS_SCHEME://nexus:$NEXUS_PORT/service/rest/v1/security/users/admin/change-password
sonarqubeRevokeTokenURL=$SONAR_SCHEME://sonarqube:$SONAR_PORT/api/user_tokens/revoke
sonarqubeGenerateTokenURL=$SONAR_SCHEME://sonarqube:$SONAR_PORT/api/user_tokens/generate
sonarqubeChangePwdURL=$SONAR_SCHEME://sonarqube:$SONAR_PORT/api/users/change_password

echo "generating new password of Nexus admin account...";
nexusInitPwd=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c32 )
echo "save New Nexus Admin Password";
curl -slL -u admin:${oldNexusPwd} -X PUT --data-raw "${nexusInitPwd}" -H "Content-Type: text/plain; charset=UTF-8" $nexusChangePwdURL
echo $nexusInitPwd >/data/secrets/nexusInitialAdminPassword

echo "generating ApiToken of jenkins admin account...";
CRUMB=$(curl -slL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL -c cookies.txt)

JenkinsApiToken=$(curl -slL -u "admin:${JenkinsPwd}" $jenkinsCreateAPITokenURL \
-H "${CRUMB}" \
--data 'newTokenName=devopsinit' \
-b cookies.txt | sed -n -e 's/"//gp' | sed -n -e 's/,/\n/gp'| grep tokenValue: | awk -F ':' '{print $2}')
JenkinsApiToken=${JenkinsApiToken%\}\}*}
echo $JenkinsApiToken > javiertest

echo "generating credential for nexus...";
CRUMB=$(curl -slL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL)
curl -s -X POST -u "admin:${JenkinsApiToken}"  -H "${CRUMB}" $jenkinsCreateCredentialsURL --data-urlencode 'json={"":"0","credentials":{"scope":"GLOBAL","id":"DevOpsNexusPassword","username":"admin","password":"'"${nexusInitPwd}"'","description":"DevOpsNexusPassword","$class":"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"}}'
sleep 5s;
echo "adding Nexus configuration to jenkins ...";
CRUMB=$(curl -slL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL)
curl -slL -X POST -u "admin:${JenkinsApiToken}" -H "${CRUMB}" $jenkinsAddNexusCfgURL --data-urlencode "id=DevOpsNexus" --data-urlencode "displayName=DevOpsNexus" --data-urlencode "serverUrl=${NEXUS_SCHEME}://${HOST}:${NEXUS_PORT}" --data-urlencode "credentialsId=DevOpsNexusPassword"


echo "generating SonarQube token...";
curl -slL -u admin:admin -X POST -d "login=admin&name=jenkins" $sonarqubeRevokeTokenURL
sonarQubeServerToken=$(curl -slL --basic -u admin:admin -X POST -d "login=admin&name=jenkins" $sonarqubeGenerateTokenURL | sed -n -e 's/"//gp' |sed -n -e 's/,/\n/gp' | grep token|awk -F ':' '{print $2}')
echo "adding SonarQube configuration to jenkins...";
CRUMB=$(curl -slL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL)
curl -slL -X POST -u "admin:${JenkinsApiToken}" -H "${CRUMB}" $jenkinsAddSonarqubeCfgURL  --data-urlencode "name=DevOpsSonarQube" --data-urlencode  "serverUrl=${SONAR_SCHEME}://${HOST}:${SONAR_PORT}" --data-urlencode "serverAuthenticationToken=${sonarQubeServerToken}"
echo "generating new password of Sonarqube admin account...";
sonarqubeInitPwd=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c32 )
echo "save New Sonarqube Admin Password";
curl -slL -u admin:admin -X POST -d "login=admin&password=${sonarqubeInitPwd}&previousPassword=admin" $sonarqubeChangePwdURL
echo $sonarqubeInitPwd >/data/secrets/sonarInitialAdminPassword

echo "configuring tapd plugin...";
/user/share/jvm/TencentKona-8.0.0-232/bin/java -jar /opt/tapd_tool.jar config-tapd --jenkinsHost="${JENKINS_SCHEME}://jenkins:${JENKINS_PORT}" --username="admin" --password="${JenkinsPwd}"

echo "save DemoPiepline";
currentTime=$(date +%s000)
demoPipelineConfig=$(cat $JENKINS_HOME/jobs/DemoPipeline/config.xml | sed 's%"%\\"%g') 
signature=$(echo -n "10${JENKINS_NAME}${JENKINS_VERSION}OP_CONFIG_UPDATE_JOB_CONFIG${TAPD_PLUGIN_VERSION}${TAPD_SECRET_TOKEN}${currentTime}" | md5sum | cut -d ' ' -f1)
echo "{\"currentTime\":${currentTime},\"data\":{\"type\":\"pipeline\",\"job_name\":\"DemoPipeline\",\"job_description\":\"这是一条Demo流水线，包含构建对象、代码检查、自动化测试、构建制品等环节。如不需使用，可以在Jenkins中删除当前Pipeline。\",\"next_build_number\":\"1\",\"build_config\":\"${demoPipelineConfig}\",\"current_workspace_id\":\"${TAPD_WORKSPACE_ID}\",\"jenkins_config_key\":\"${newJenkinsJobUuid}\",\"pipeline_name\":\"\",\"triggersize\":\"0\",\"job_relations\":\"\"},\"jenkinsName\":\"${JENKINS_NAME}\",\"jenkinsVersion\":\"${JENKINS_VERSION}\",\"opType\":\"OP_CONFIG_UPDATE_JOB_CONFIG\",\"pluginVersion\":\"${TAPD_PLUGIN_VERSION}\",\"secretToken\":\"${TAPD_SECRET_TOKEN}\",\"signature\":\"${signature}\",\"status\":\"1\"}" > tmp.json
curl -slL -X POST -d "@tmp.json" -H "Content-type: application/json" ${TAPD_WEB_HOOK_URL}?HTTP_X_JENKINS_EVENT=HTTP_X_JENKINS_EVENT

echo -e "\ntrigger build"
CRUMB=$(curl -slL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL)
curl -slL -X POST -u "admin:${JenkinsApiToken}" -H "${CRUMB}" -H "application/x-www-form-urlencoded" --data-urlencode 'tapd_info={"ipipeBuildId":0,"cause":"admin","system_default_build_user":"admin"}' $jenkinsDemoPipelineBuildURL

echo -e "\nJenkins Password for admin is \n********************************\n${JenkinsPwd} \n********************************\nyou also can find it in /data/secrets/jenkinsInitialAdminPassword\n"
echo -e "Nexus Password for admin is \n********************************\n${nexusInitPwd} \n******************************** \nyou also can find it in /data/secrets/nexusInitialAdminPassword\n"
echo -e "Sonarqube Password for admin is \n********************************\n${sonarqubeInitPwd} \n******************************** \nyou also can find it in /data/secrets/sonarInitialAdminPassword\n"

echo -e "\n\nInitializing Finished\n\n"

touch $INIT_FILE