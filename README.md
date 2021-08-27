## Intro
从零开始安装配置Jenkins、SonarQube、Nexus等相关工具是一件比较复杂的事，有没有什么办法可以跳过繁琐的环境搭建，直接体验强大的Devops流水线呢？现在你只需安装好 Docker-CE ，就可以使用Devops镜像一键搭建好这些集成工具了。

## Feature 
- 使用Docker 多阶段构建
- 使用Tencent Kona JDK
- 参数化构建，各组件版本可控
- 预留端口可供服务扩展
- 一键安装，自动配置
## Usage

### build
```
docker build \
--build-arg JENKINS_IMAGE=jenkins/jenkins:2.235.5-lts-alpine \
--build-arg SONARQUBE_IMAGE=sonarqube:8.9.0-community \
--build-arg NEXUS_IMAGE=sonatype/nexus3:3.26.1 \
 -t ${IMAGE_NAME} .

```

### run
```
docker run \
-e HOST=${HOST} \
-e token=${TOKEN} \
-e JENKINS_PORT=${JENKINS_PORT} \
-e SONAR_PORT=${SONAR_PORT} \
-e NEXUS_PORT=${NEXUS_PORT} \
-p ${JENKINS_PORT}:8080 -p ${NEXUS_PORT}:8081 -p ${SONAR_PORT}:9000 -p ${JENKINS_AGENT_PORT}:50000 \
-dit -v ${DATA_VOLUME}}:/data/devops_data \
--name=${CONTAINER_NAME} ${IMAGE_NAME}
```

| 环境变量     | 说明                              |
| ------------ | --------------------------------|
| HOST         | 必填，你的服务外网可访问的Host      |
| TOKEN        | 必填，你的服务和TAPD关联的访问令牌   |
| JENKINS_PORT | 你的Jenkins服务的端口，默认8080    |
| SONAR_PORT   | 你的Sonar服务的端口，默认9000      |
| NEXUS_PORT   | 你的Nexus服务的端口，默认8081      |

| 运行参数     | 说明                              |
| ------------ | --------------------------------|
| IMAGE_NAME   | 你的镜像名（必填）                 |
| DATA_VOLUME  | 你的数据挂载卷（可选               |
| CONTAINER_NAME  | 你的容器名（可选）              |
| JENKINS_AGENT_PORT   | 你的JENKINS_AGENT(可选)的端口，默认50000  |


#### init log
```
docker logs -f ${CONTAINER_NAME}
```

### secrets
```
#cat jenkins password
docker exec -it ${CONTAINER_NAME} cat /data/devops_data/secrets/jenkinsInitialAdminPassword

#cat sonar password
docker exec -it ${CONTAINER_NAME} cat /data/devops_data/secrets/sonarInitialAdminPassword

#cat nexus password
docker exec -it ${CONTAINER_NAME} cat /data/devops_data/secrets/nexusInitialAdminPassword
```

### access

- jenkins: ${HOST}:{JENKINS_PORT}

- sonar: ${HOST}:{SONAR_PORT}

- nexus: ${HOST}:{NEXUS_PORT}