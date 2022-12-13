
import hudson.ExtensionList
import org.sonatype.nexus.ci.config.GlobalNexusConfiguration
import org.sonatype.nexus.ci.config.Nxrm3Configuration
import org.sonatype.nexus.ci.config.NxrmConfiguration
import hudson.plugins.sonar.SonarGlobalConfiguration
import hudson.plugins.sonar.SonarInstallation

println "4-create-sonar-nexus-system-config.groovy"

doNexus()
doSonar()

def doNexus() {
  String id = "DevOpsNexus"
  String displayName = "DevOpsNexus"
  String serverUrl = System.getenv("nexus_host") + ":" + System.getenv("nexus_port")
  String credentialsId = "DevOpsNexusPassword"

  GlobalNexusConfiguration globalNexusConfiguration = ExtensionList.lookupSingleton(GlobalNexusConfiguration)
  Nxrm3Configuration nxrm3Configuration = new Nxrm3Configuration(id, UUID.randomUUID().toString(), displayName, serverUrl, credentialsId)
  List<NxrmConfiguration> nxrmConfigurationList = new ArrayList<>()
  nxrmConfigurationList.add(nxrm3Configuration)
  globalNexusConfiguration.setNxrmConfigs(nxrmConfigurationList)
  globalNexusConfiguration.save()
}

def doSonar() {
  String id = "DevOpsSonarQube"
  String displayName = "DevOpsSonarQube"
  String serverUrl = System.getenv("sonar_host") + ":" + System.getenv("sonar_port")
  String credentialsId = "DevOpsSonarQubeToken"

  SonarGlobalConfiguration sonarGlobalConfiguration = ExtensionList.lookupSingleton(SonarGlobalConfiguration)
  SonarInstallation newInstanceItem = new SonarInstallation(id, serverUrl, credentialsId, null, "", "", "", "", null)
  SonarInstallation[] sonarInstallations = [newInstanceItem]
  sonarGlobalConfiguration.setInstallations(sonarInstallations)
}