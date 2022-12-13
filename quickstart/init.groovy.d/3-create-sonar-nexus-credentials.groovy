import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import groovy.json.JsonSlurper
import hudson.util.Secret
import hudson.AbortException

println "3-create-sonar-nexus-credentials.groovy"

// revoking SonarQube token
def revokePost = new URL(System.getenv("sonar_host") + ":" + System.getenv("sonar_port") +"/api/user_tokens/revoke").openConnection();
def message = "login="+System.getenv("sonarqube_user")+"&name=jenkins"
def basicAuth = System.getenv("sonarqube_user")+":"+System.getenv("sonarqube_user_password")
String encodedBasicAuth = basicAuth.bytes.encodeBase64().toString()

revokePost.setRequestMethod("POST")
revokePost.setDoOutput(true)
revokePost.setRequestProperty("Authorization", "Basic " + encodedBasicAuth)
revokePost.getOutputStream().write(message.getBytes("UTF-8"));
def revokePostRC = revokePost.getResponseCode();
if(!revokePostRC.equals(204)) {
  throw new AbortException("revoke sonarqube faild")
}

// generating SonarQube token
def generatePost = new URL(System.getenv("sonar_host") + ":" + System.getenv("sonar_port") +"/api/user_tokens/generate").openConnection();

generatePost.setRequestMethod("POST")
generatePost.setDoOutput(true)
generatePost.setRequestProperty("Authorization", "Basic " + encodedBasicAuth)
generatePost.getOutputStream().write(message.getBytes("UTF-8"));
def generatePostRC = generatePost.getResponseCode();
if(generatePostRC.equals(200)) {
    def jsonSlurper = new JsonSlurper()
    def object = jsonSlurper.parseText(generatePost.getInputStream().getText())
    System.setProperty("sonarqube_user_token", object.token)    
}else{
  throw new AbortException("generate sonarqube faild")
}

Credentials nexusCredentials = (Credentials) new UsernamePasswordCredentialsImpl(CredentialsScope.GLOBAL,"DevOpsNexusPassword", "DevOpsNexusPassword", System.getenv("nexus_user"), System.getenv("nexus_user_password"))
Credentials sonarCredentials = (Credentials) new StringCredentialsImpl(CredentialsScope.GLOBAL,"DevOpsSonarQubeToken", "DevOpsSonarQubeToken", Secret.fromString(System.getProperty("sonarqube_user_token")))

SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), nexusCredentials)
SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), sonarCredentials)