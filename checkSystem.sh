#! /bin/bash


#磁盘容量是否大于等于20G

if test -z "$(df -h|awk '($6=="/"){ print}'| awk '{print $4}'| grep G)"; then
	echo -e "error code:201\nerror msg:Disk capacity must be no less than 20g"
    exit 1
fi


availableSize=`df -h|awk '($6=="/"){ print}'| awk '{print $4}'| sed 's/G//g'| awk '{print int($0)}'`

if [ $availableSize -lt 20 ];then
	echo  "error code:201\nerror msg:Disk capacity must be no less than 20g"
	exit 1
fi


#网络是否畅通
function network()
{
    local timeout=20
    local target=https://www.tapd.cn
    local ret_code=`curl -I -s --connect-timeout ${timeout} ${target} -w %{http_code} | tail -n1`
    if [ "x$ret_code" = "x200" ]; then
        return 1
    else
        return 0
    fi
    return 0
}
echo "testing network..."
network
if [ $? -eq 0 ];then
    echo -e "error code:202\nerror msg:Invalid network"
    exit 1
fi
echo "network test successfully"





