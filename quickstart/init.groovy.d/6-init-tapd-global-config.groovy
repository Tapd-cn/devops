import com.tencent.tapd.jenkins.plugins.pipeline.TapdConfigLink
import com.tencent.tapd.jenkins.plugins.pipeline.TapdEventConstant
import com.tencent.tapd.jenkins.plugins.pipeline.util.TapdLog
import com.tencent.tapd.model.TapdWebHook
import com.tencent.tapd.model.TapdRequest
import com.tencent.tapd.model.Response
import net.sf.json.JSONObject
import hudson.ExtensionList

println "6-init-tapd-global-config.groovy"

String url = System.getProperty("tapd_web_hook_url")
String secretToken = System.getProperty("tapd_secret_token")
String workspaceId = System.getProperty("tapd_workspace_id")
String jenkinsName = System.getProperty("jenkins_name")
String apiToken = System.getProperty("admin_api_token")
String jenkinsVisitAddress = System.getenv("jenkins_visit_address")

TapdConfigLink tcl = ExtensionList.lookupSingleton(TapdConfigLink)

tcl.setJenkinsName(jenkinsName)
tcl.setJenkinsUser(System.getenv("jenkins_user"))
tcl.setJenkinsVisitAddress(jenkinsVisitAddress)
tcl.setJenkinsToken(apiToken)
String newJenkinsTag = UUID.randomUUID().toString()
tcl.setJenkinsTag(newJenkinsTag)

boolean shouldSave = false

JSONObject configBean = new JSONObject()
configBean.put("jenkins_user_name",tcl.getJenkinsUser())
configBean.put("api_token", tcl.getJenkinsToken())
configBean.put("jenkins_visit_address", tcl.getJenkinsVisitAddress())
configBean.put("relate_workspace_id", workspaceId)
configBean.put("jenkins_tag", newJenkinsTag)

TapdWebHook newFirstWebHook = null
ArrayList<TapdWebHook> newTapdWebHooks = new ArrayList<TapdWebHook>()


String errorMsg = ""

TapdWebHook currentWebhook = new TapdWebHook(url, secretToken)
currentWebhook.setWorkspaceId(workspaceId)
TapdRequest tapdRequest = new TapdRequest(TapdEventConstant.OP_CONFIG_SAVE_GLOBAL_CONFIG, configBean)
Response response = tapdRequest.executeByParams(currentWebhook.getUrl(),
        currentWebhook.getSecretToken(),
        tcl.getJenkinsName())

if (null == response) {
    errorMsg = errorMsg + "保存失败\n"
    TapdLog.error("配置保存失败")
} else if (response.isSuccess()) {
    Map<String, String> mapData = response.getData()
    String resWorkspaceId = mapData.getOrDefault("workspace_id", "")
    if (!"".equals(resWorkspaceId)) {
      currentWebhook.setWorkspaceId(resWorkspaceId)
      shouldSave = true
      newFirstWebHook = currentWebhook        
    }
} else {
    errorMsg = errorMsg + response.getErrorMessage() + "\n"
    TapdLog.error("配置保存失败" + response.getErrorMessage())
}
if (shouldSave) {
    tcl.setFirstWebHook(newFirstWebHook)
    tcl.setTapdWebHooks(newTapdWebHooks)
    tcl.save()
} else {
    TapdLog.error("配置保存失败" + errorMsg)
}
TapdLog.info("提交配置保存记录成功!")