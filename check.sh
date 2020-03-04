# check if environments are valid
if [ -z $SONAR_SCHEME ]; then
    echo -e "\033[31merror code:101\nerror msg:SONAR_SCHEME is not set\033[0m";
    exit 1;
fi
if [ -z $NEXUS_SCHEME ]; then
    echo -e "\033[31merror code:102\nerror msg:NEXUS_SCHEME is not set\033[0m";
    exit 1;
fi

if [ -z $SONAR_PORT ]; then
    echo -e "\033[31merror code:103\nerror msg:SONAR_PORT is not set\033[0m";
    exit 1;
fi

if [ -z $NEXUS_PORT ]; then
    echo -e "\033[31merror code:104\nerror msg:NEXUS_PORT is not set\033[0m";
    exit 1;
fi

if [ -z $HOST ]; then
    echo -e "\033[31merror code:105\nerror msg:HOST is not set\033[0m";
    exit 1;
fi

if [ ! -f "$INIT_FILE" ]; then
    if [ -z $token ]; then
        echo -e "\033[31merror code:106\nerror msg:token is not set\033[0m"
        exit 1
    fi
fi

echo "environment variables are all set. start configuring...";