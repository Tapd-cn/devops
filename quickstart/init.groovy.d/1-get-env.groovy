import hudson.AbortException

println "execute 1-get-env.groovy"

String hash = System.getenv("tapd_auth_secret")
String tapdAuthPre= System.getenv("tapd_auth_url")

// GET
def get = new URL(tapdAuthPre+hash).openConnection();
def getRC = get.getResponseCode();
if(getRC.equals(200)){
  String[] ret = get.getInputStream().getText().split("\\|")
  System.setProperty("tapd_workspace_id", ret[0])
  System.setProperty("jenkins_name", ret[1])
  System.setProperty("tapd_web_hook_url", ret[2])
  System.setProperty("tapd_secret_token", ret[3])
}else{
  throw new AbortException("TAPD auth faild")
}