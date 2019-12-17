#! /bin/bash -e
export TAPD_WORKSPACE_ID=${tapdAuthInfoArray[0]}
export JENKINS_NAME=${tapdAuthInfoArray[1]}
export TAPD_WEB_HOOK_URL=${tapdAuthInfoArray[2]}
export TAPD_SECRET_TOKEN=${tapdAuthInfoArray[3]}