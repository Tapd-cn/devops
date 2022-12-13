# check if environments are valid
if [ -z $SONAR_PORT ]; then
    echo "SONAR_PORT is not set";
    exit 1;
fi

if [ -z $NEXUS_PORT ]; then
    echo "NEXUS_PORT is not set";
    exit 1;
fi

if [ -z $HOST ]; then
    echo "HOST is not set";
    exit 1;
fi

if [ ! -f "$INIT_FILE" ]; then
    if [ -z $token ]; then
        echo "token is not set"
        exit 1
    fi
fi

echo "environment variables are all set. start configuring...";