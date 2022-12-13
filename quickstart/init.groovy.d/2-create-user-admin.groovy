#!/usr/bin/env groovy
import jenkins.model.*
import hudson.security.*

// Required plugins: 
// (none)
//
println "execute 2-create-user-admin.groovy"

def instance = Jenkins.getInstance()

println "--> creating local user 'admin'"

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(System.getenv("jenkins_user"),System.getenv("jenkins_user_password"))
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)

instance.save()