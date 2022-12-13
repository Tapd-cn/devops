// Adds a pipeline job to jenkins
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import org.jenkinsci.plugins.workflow.flow.FlowDefinition
import com.tencent.tapd.jenkins.plugins.pipeline.job.TapdPipeLineJobProperty
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec
import hudson.plugins.git.UserRemoteConfig
import com.cloudbees.hudson.plugins.folder.*

println "7-create-demo-workflow-job.groovy"

// Required plugins: 
// - git
// - workflow-aggregator
// - tapd
//

// Variables
String jobName = "DemoPipeline"
String jobDescription = "这是一条Demo流水线，包含构建对象、代码检查、自动化测试、构建制品等环节。如不需使用，可以在Jenkins中删除当前Pipeline。"
String jobScript = "Jenkinsfile"
String gitRepo = "https://github.com/Tapd-cn/simple-jenkins-demo-pipeline.git"
String gitRepoName = "simple-jenkins-demo-pipeline"
String gitRepoBranches = "*/master"
String credentialsId = ""

String workspaceId = System.getProperty("tapd_workspace_id")


// Create pipeline
Jenkins jenkins = Jenkins.instance

// Create the git configuration
UserRemoteConfig userRemoteConfig = new UserRemoteConfig(gitRepo, gitRepoName, null, credentialsId)
branches = Collections.singletonList(new BranchSpec(gitRepoBranches))
doGenerateSubmoduleConfigurations = false
submoduleCfg = null
browser = null
gitTool = null
extensions = []
GitSCM scm = new GitSCM([userRemoteConfig], branches, doGenerateSubmoduleConfigurations, submoduleCfg, browser, gitTool, extensions)

// Create the workflow
FlowDefinition flowDefinition = (FlowDefinition) new CpsScmFlowDefinition(scm, jobScript)

// Create job
job = jenkins.createProject(WorkflowJob, jobName)
TapdPipeLineJobProperty javernb = new TapdPipeLineJobProperty(workspaceId,UUID.randomUUID().toString(),"")
// Add the workflow to the job
job.setDefinition(flowDefinition)
job.addProperty(javernb)
job.description = jobDescription

// Save
job.save()