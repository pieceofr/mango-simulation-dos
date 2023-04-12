#!/usr/bin/env bash
function read_machines() {
    ip_file=instance_ip.out
    name_file=instance_name.out
    zone_file=instance_ip.out
}

## provide filename in bucket
download_file() {
	for retry in 0 1
	do
		if [[ $retry -gt 1 ]];then
			break
		fi
		gsutil cp  gs://mango_bencher-dos/$1 ./
		if [[ ! -f "$1" ]];then
			echo "NO $1 found, retry"
            sleep 5
		else
			break
		fi
	done
}
function get_testnet_ver() {
    local ret
    for retry in 0 1 2
    do
        if [[ $retry -gt 1 ]];then
            break
        fi
        ret=$(curl $ENDPOINT -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getVersion"}
        ' | jq '.result."solana-core"' | sed 's/\"//g') || true
        echo get_testnet_ver ret: $ret
        if [[ $ret =~ [0-9]+.[0-9]+.[0-9]+ ]];then
            echo get version
            break
        fi
        sleep 3
    done
    if [[ ! $ret =~ ^[0-9]+.[0-9]+.[0-9]+ ]];then
        testnet_ver=master
        break
    else
        #adding a v because the branch has a v
        testnet_ver=$(echo v$ret)
    fi
}

# given time $1 and get after $2 seconds
get_time_after() {
	outcom_in_sec=$(echo $1 + $2 | bc) 
}

# given time $1 and get before $2 seconds
get_time_before() {
	outcom_in_sec=$(echo $1 - $2 | bc) 
}