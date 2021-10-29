##使用Docker 多阶段构建

##使用Tencent Kona JDK



##Usage

###build
docker build --build-arg JENKINS_IMAGE=jenkins/jenkins:2.224 --build-arg TAPD_PLUGIN_VERSION=1.6.2.20210722  -t javier-jenkins-test .

###run
docker run -d -p 8099:8080 javier-jenkins-test


##Docker compose usage

###configure
cp .env.example .env

###run
docker-compose up -d

###stop
docker-compose down -v


