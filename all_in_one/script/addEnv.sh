#! /bin/bash -e
tapdAuthPre="https://www.tapd.cn/devops/auth/index/"

tapdAuthInfo=$(curl -s $tapdAuthPre$token)
if [ -z $tapdAuthInfo ] || [ $tapdAuthInfo == "error" ]; then
    echo "TAPD auth faild"
    exit 1
fi
tapdAuthInfoArray=(${tapdAuthInfo//|/ })

export TAPD_WORKSPACE_ID=${tapdAuthInfoArray[0]}
export JENKINS_NAME=${tapdAuthInfoArray[1]}
export TAPD_WEB_HOOK_URL=${tapdAuthInfoArray[2]}
export TAPD_SECRET_TOKEN=${tapdAuthInfoArray[3]}