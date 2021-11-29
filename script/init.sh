#! /bin/bash -e

echo "waiting for jenkins starting fully..."
sleep 20s

# set jenkins environment variable end
echo "Waiting for initializing data... This may take some time ..."
sleep 30s

JenkinsPwd=$(cat /data/devops_data/secrets/jenkinsInitialAdminPassword)
oldNexusPwd=$(cat $NEXUS_DATA/admin.password)

# generate url
jenkinsCrumbTokenURL=http://localhost:8080/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\)
jenkinsCreateAPITokenURL=http://localhost:8080/user/admin/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken
jenkinsCreateCredentialsURL=http://localhost:8080/credentials/store/system/domain/_/createCredentials
jenkinsAddNexusCfgURL=http://localhost:8080/tapd-devops-init/nexus
jenkinsAddSonarqubeCfgURL=http://localhost:8080/tapd-devops-init/sonar
jenkinsDemoPipelineBuildURL=http://localhost:8080/job/DemoPipeline/tapdbuild/build
nexusChangePwdURL=http://localhost:8081/service/rest/v1/security/users/admin/change-password
sonarqubeRevokeTokenURL=http://localhost:9000/api/user_tokens/revoke
sonarqubeGenerateTokenURL=http://localhost:9000/api/user_tokens/generate
sonarqubeChangePwdURL=http://localhost:9000/api/users/change_password

echo "generating new password of Nexus admin account...";
nexusInitPwd=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c32 )
echo "save New Nexus Admin Password";
curl -slL -u admin:${oldNexusPwd} -X PUT --data-raw "${nexusInitPwd}" -H "Content-Type: text/plain; charset=UTF-8" $nexusChangePwdURL
echo $nexusInitPwd >/data/devops_data/secrets/nexusInitialAdminPassword
echo "------------------------------------TAPD DEBUG START------------------------------------";
echo ">>>>>>>>>>>>>>>>>>>>>>>SHOW JENKINS PASSWORD START"
echo "jenkins password is ${JenkinsPwd}"
echo ">>>>>>>>>>>>>>>>>>>>>>>SHOW JENKINS PASSWORD END"

echo ">>>>>>>>>>>>>>>>>>>>>>>SHOW JENKINS CrumbTokenURL START"
echo "jenkins CrumbTokenURL is ${jenkinsCrumbTokenURL}"
echo ">>>>>>>>>>>>>>>>>>>>>>>SHOW JENKINS CrumbTokenURL END"

echo ">>>>>>>>>>>>>>>>>>>>>>>EXECUTE generating JENKINs ApiToken START"
echo "generating ApiToken of jenkins admin account...";
echo "=======================part1 generating JENKINs CRUMB START"
echo "curl -vlL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL -c cookies.txt"
CRUMB=$(curl -vlL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL -c cookies.txt)
echo "=======================part1 generating JENKINs CRUMB END"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "=======================part2 SHOW JENKINs CRUMB START"
echo "${CRUMB}"
echo "=======================part2 SHOW JENKINs CRUMB END"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "=======================part3 SHOW cookies.txt START"
cat cookies.txt
echo "=======================part3 SHOW cookies.txt END"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "=======================part4 generating JenkinsApiToken START"
echo "curl -slL -u \"admin:${JenkinsPwd}\" $jenkinsCreateAPITokenURL \
-H \"${CRUMB}\" \
--data 'newTokenName=devopsinit' \
-b cookies.txt | sed -n -e 's/\"//gp' | sed -n -e 's/,/\n/gp'| grep tokenValue: | awk -F ':' '{print $2}'"

JenkinsApiToken=$(curl -vlL -u "admin:${JenkinsPwd}" $jenkinsCreateAPITokenURL \
-H "${CRUMB}" \
--data 'newTokenName=devopsinit' \
-b cookies.txt | sed -n -e 's/"//gp' | sed -n -e 's/,/\n/gp'| grep tokenValue: | awk -F ':' '{print $2}')
echo "=======================part4 generating JenkinsApiToken END"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "=======================part5 SHOW JenkinsApiToken START"
echo "${JenkinsApiToken}"
echo "JenkinsApiToken=${JenkinsApiToken%\\}\\}*}"
JenkinsApiToken=${JenkinsApiToken%\}\}*}
echo "${JenkinsApiToken}"
echo "=======================part5 SHOW JenkinsApiToken END"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "=======================part6 SHOW cookies.txt START"
cat cookies.txt
echo "=======================part6 SHOW cookies.txt END"
echo ">>>>>>>>>>>>>>>>>>>>>>>EXECUTE generating JENKINs ApiToken END"

echo ">>>>>>>>>>>>>>>>>>>>>>>EXECUTE credential for nexus START"
echo "generating credential for nexus...";
echo "=======================part1 generating JENKINs CRUMB START"
echo "curl -vlL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL"
CRUMB=$(curl -vlL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL)
echo "=======================part1 generating JENKINs CRUMB END"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "=======================part2 SHOW JENKINs CRUMB START"
echo "${CRUMB}"
echo "=======================part2 SHOW JENKINs CRUMB END"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "=======================part3 generating JenkinsApiToken START"
echo "curl -v -X POST -u \"admin:${JenkinsApiToken}\"  -H \"${CRUMB}\" $jenkinsCreateCredentialsURL --data-urlencode 'json={\"\":\"0\",\"credentials\":{\"scope\":\"GLOBAL\",\"id\":\"DevOpsNexusPassword\",\"username\":\"admin\",\"password\":\"'\"${nexusInitPwd\"'\",\"description\":\"DevOpsNexusPassword\",\"$class\":\"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\"}}'"
curl -v -X POST -u "admin:${JenkinsApiToken}"  -H "${CRUMB}" $jenkinsCreateCredentialsURL --data-urlencode 'json={"":"0","credentials":{"scope":"GLOBAL","id":"DevOpsNexusPassword","username":"admin","password":"'"${nexusInitPwd}"'","description":"DevOpsNexusPassword","$class":"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"}}'
echo "=======================part3 generating JenkinsApiToken END"
echo ">>>>>>>>>>>>>>>>>>>>>>>EXECUTE credential for nexus END"

echo "------------------------------------TAPD DEBUG END------------------------------------";
sleep 5;

echo "adding Nexus configuration to jenkins ...";
CRUMB=$(curl -slL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL)
curl -slL -X POST -u "admin:${JenkinsApiToken}" -H "${CRUMB}" $jenkinsAddNexusCfgURL --data-urlencode "id=DevOpsNexus" --data-urlencode "displayName=DevOpsNexus" --data-urlencode "serverUrl=http://${HOST}:${NEXUS_PORT}" --data-urlencode "credentialsId=DevOpsNexusPassword"


echo "generating SonarQube token...";
curl -slL -u admin:admin -X POST -d "login=admin&name=jenkins" $sonarqubeRevokeTokenURL
sonarQubeServerToken=$(curl -slL --basic -u admin:admin -X POST -d "login=admin&name=jenkins" $sonarqubeGenerateTokenURL | sed -n -e 's/"//gp' |sed -n -e 's/,/\n/gp' | grep token|awk -F ':' '{print $2}')
echo "generating credential for sonar...";
CRUMB=$(curl -slL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL)
curl -s -X POST -u "admin:${JenkinsApiToken}"  -H "${CRUMB}" $jenkinsCreateCredentialsURL --data-urlencode 'json={"":"0","credentials":{"scope":"GLOBAL","id":"DevOpsSonarQubeToken","secret":"'"${sonarQubeServerToken}"'","description":"DevOpsSonarQubeToken","$class":"org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl"}}'
sleep 5;
echo "adding SonarQube configuration to jenkins...";
CRUMB=$(curl -slL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL)
curl -slL -X POST -u "admin:${JenkinsApiToken}" -H "${CRUMB}" $jenkinsAddSonarqubeCfgURL  --data-urlencode "name=DevOpsSonarQube" --data-urlencode  "serverUrl=http://${HOST}:${SONAR_PORT}" --data-urlencode "credentialsId=DevOpsSonarQubeToken"
echo "generating new password of Sonarqube admin account...";
sonarqubeInitPwd=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c32 )
echo "save New Sonarqube Admin Password";
curl -slL -u admin:admin -X POST -d "login=admin&password=${sonarqubeInitPwd}&previousPassword=admin" $sonarqubeChangePwdURL
echo $sonarqubeInitPwd >/data/devops_data/secrets/sonarInitialAdminPassword

echo "configuring tapd plugin...";
/user/share/jvm/TencentKona-8.0.0-232/bin/java -jar /opt/tapd_tool.jar config-tapd --username="admin" --password="${JenkinsPwd}"

echo "save DemoPiepline";
currentTime=$(date +%s000)
demoPipelineConfig=$(cat $JENKINS_HOME/jobs/DemoPipeline/config.xml | sed 's%"%\\"%g') 
signature=$(echo -n "10${JENKINS_NAME}${JENKINS_VERSION}OP_CONFIG_UPDATE_JOB_CONFIG${TAPD_PLUGIN_VERSION}${TAPD_SECRET_TOKEN}${currentTime}" | md5sum | cut -d ' ' -f1)
echo "{\"currentTime\":${currentTime},\"data\":{\"type\":\"pipeline\",\"job_name\":\"DemoPipeline\",\"job_description\":\"这是一条Demo流水线，包含构建对象、代码检查、自动化测试、构建制品等环节。如不需使用，可以在Jenkins中删除当前Pipeline。\",\"next_build_number\":\"1\",\"build_config\":\"${demoPipelineConfig}\",\"current_workspace_id\":\"${TAPD_WORKSPACE_ID}\",\"jenkins_config_key\":\"${newJenkinsJobUuid}\",\"pipeline_name\":\"\",\"triggersize\":\"0\",\"job_relations\":\"\"},\"jenkinsName\":\"${JENKINS_NAME}\",\"jenkinsVersion\":\"${JENKINS_VERSION}\",\"opType\":\"OP_CONFIG_UPDATE_JOB_CONFIG\",\"pluginVersion\":\"${TAPD_PLUGIN_VERSION}\",\"secretToken\":\"${TAPD_SECRET_TOKEN}\",\"signature\":\"${signature}\",\"status\":\"1\"}" > tmp.json
curl -slL -X POST -d "@tmp.json" -H "Content-type: application/json" ${TAPD_WEB_HOOK_URL}?HTTP_X_JENKINS_EVENT=HTTP_X_JENKINS_EVENT

echo -e "\ntrigger build"
CRUMB=$(curl -slL -u "admin:${JenkinsPwd}" $jenkinsCrumbTokenURL)
curl -slL -X POST -u "admin:${JenkinsApiToken}" -H "${CRUMB}" -H "application/x-www-form-urlencoded" --data-urlencode 'tapd_info={"ipipeBuildId":0,"cause":"admin","system_default_build_user":"admin"}' $jenkinsDemoPipelineBuildURL

echo -e "\nJenkins Password for admin is \n********************************\n${JenkinsPwd} \n********************************\nyou also can find it in /data/devops_data/secrets/jenkinsInitialAdminPassword\n"
echo -e "Nexus Password for admin is \n********************************\n${nexusInitPwd} \n******************************** \nyou also can find it in /data/devops_data/secrets/nexusInitialAdminPassword\n"
echo -e "Sonarqube Password for admin is \n********************************\n${sonarqubeInitPwd} \n******************************** \nyou also can find it in /data/devops_data/secrets/sonarInitialAdminPassword\n"

echo -e "\n\nInitializing Finished\n\n"

touch $INIT_FILE