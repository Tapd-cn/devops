import hudson.model.User
import jenkins.security.ApiTokenProperty
import jenkins.security.apitoken.TokenUuidAndPlainValue

println "5-get-user-admin-api-token.groovy"

User u = User.get(System.getenv("jenkins_user"))  
ApiTokenProperty t = u.getProperty(ApiTokenProperty.class)  
TokenUuidAndPlainValue token = t.generateNewToken('devopsinit')

System.setProperty("admin_api_token", token.plainValue)