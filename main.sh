
#!/usr/bin/env bash
set -ex
# Check ENVS
## mango_bench setup ENVS
[[ ! "$RUST_LOG" ]]&& RUST_LOG=info && echo RUST_LOG env not found, use $RUST_LOG
[[ ! "$ENDPOINT" ]]&& echo ENDPOINT env not found && exit 1
[[ ! "$DURATION" ]]&& echo DURATION env not found && exit 1
[[ ! "$QOUTES_PER_SECOND" ]]&& echo ENDPOINT env not found && exit 1
[[ ! "$ACCOUNTS" ]]&& ACCOUNTS="accounts-1_20.json accounts-2_20.json accounts-3_10.json" && echo ACCOUNTS not found, use $ACCOUNTS
[[ ! "$AUTHORITY_FILE" ]] && AUTHORITY_FILE=authority.json && echo AUTHORITY_FILE , use $AUTHORITY_FILE
[[ ! "$ID_FILE" ]] && ID_FILE=ids.json && echo ID_FILE , use $ID_FILE
## keeper_run run ENVS
[[ ! "$CLUSTER" ]] && KEEPER_CLUSTER=testnet && echo KEEPER_CLUSTER , use $KEEPER_CLUSTER
[[ ! "$KEEPER_GROUP" ]] && KEEPER_GROUP=testnet && echo KEEPER_GROUP , use $KEEPER_GROUP
[[ ! "$KEEPER_ENDPOINT" ]] && KEEPER_ENDPOINT="api.testnet.solana.com" && echo KEEPER_ENDPOINT , use $KEEPER_ENDPOINT
## solana build repo ENVS
[[ ! "$MANGO_BENCHER_REPO" ]]&& MANGO_BENCHER_REPO=https://github.com/solana-labs/mango-simulation.git && echo MANGO_BENCHER_REPO env not found, use $MANGO_BENCHER_REPO
[[ ! "$MANGO_BENCHER_BRANCH" ]]&& MANGO_BENCHER_BRANCH=main && echo MANGO_BENCHER_BRANCH env not found, use $MANGO_BENCHER_BRANCH
[[ ! "$MANGO_CONFIGURE_REPO" ]]&& MANGO_CONFIGURE_REPO=https://github.com/solana-labs/configure_mango.git && echo MANGO_CONFIGURE_REPO env not found, use $MANGO_CONFIGURE_REPO
[[ ! "$MANGO_CONFIGURE_BRANCH" ]]&& MANGO_CONFIGURE_BRANCH=main && echo MANGO_CONFIGURE_BRANCH env not found, use $MANGO_CONFIGURE_BRANCH


## CI program ENVS
[[ ! "$GIT_TOKEN" ]]&& echo GIT_TOKEN env not found && exit 1
[[ ! "$GIT_REPO" ]]&& GIT_REPO=$BUILDKITE_REPO && GIT_REPO not found, use $GIT_REPO
[[ ! "$NUM_CLIENT" || $NUM_CLIENT -eq 0 ]]&& echo NUM_CLIENT env invalid && exit 1
[[ ! "$AVAILABLE_ZONE" ]]&& echo AVAILABLE_ZONE env not found && exit 1
[[ ! "$SLACK_WEBHOOK" ]]&&[[ ! "$DISCORD_WEBHOOK" ]]&& echo no WEBHOOK found && exit 1
[[ ! "$RUN_BENCH_AT_TS_UTC" ]]&& RUN_BENCH_AT_TS_UTC=0 && echo RUN_BENCH_AT_TS_UTC env not found, use $RUN_BENCH_AT_TS_UTC
[[ ! "$KEEP_INSTANCES" ]]&& KEEP_INSTANCES="false" && echo KEEP_INSTANCES env not found, use $KEEP_INSTANCES
source utils.sh
## Directory settings
dos_program_dir=$(pwd)
BUILD_DEPENDENCY_BENCHER_DIR=/home/sol/mango_simulation
BUILD_DEPENDENCY_CONFIGURE_DIR=/home/sol/configure_mango

echo ----- stage: prepare metrics env ------ 
[[ -f "dos-metrics-env.sh" ]]&& rm dos-metrics-env.sh
download_file dos-metrics-env.sh
[[ ! -f "dos-metrics-env.sh" ]]&& echo "NO dos-metrics-env.sh found" && exit 1
source dos-metrics-env.sh

echo ----- stage: prepare ssh key to dynamic clients ------
download_file id_ed25519_dos_test
[[ ! -f "id_ed25519_dos_test" ]]&& echo "no id_ed25519_dos_test found" && exit 1
chmod 600 id_ed25519_dos_test
ls -al id_ed25519_dos_test

echo ----- stage: get cluster version and git information for buildkite-agent --- 
get_testnet_ver

echo ----- stage: prepare files to run the mango_bencher in the clients --- 
# setup Envs here so that generate-exec-files.sh can be used individually
source generate-exec-dependency.sh
accounts=( $ACCOUNTS )
#Generate first dos-test machine
source generate-exec-dos-test.sh
acct_num=1
for acct in "${accounts[@]}"
do
    ACCOUNT_FILE=$acct
    [[ acct_num -ne 1 ]]&& RUN_KEEPER="false"
    echo RUN_KEEPER=$RUN_KEEPER
    gen_dos_test $acct_num
    let acct_num=$acct_num+1
done

echo ----- stage: machines and build and upload mango-simulation ---
cd $dos_program_dir
source create-instance.sh
create_machines $NUM_CLIENT
echo ----- stage: build dependency mango_bencher configure_mango for 1st machine------
client_num=1
for sship in "${instance_ip[@]}"
do
    if $client_num -eq 1;then
        ret_pre_build=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship 'bash -s' < exec-start-build-dependency-build.sh)
    else
        ret_pre_build=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship 'bash -s' < exec-start-build-dependency-download.sh)
    fi
    let client_num=$client_num+1
done


echo ----- stage: run dos test ---
client_num=1
for sship in "${instance_ip[@]}"
do
    ret_run_dos=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship 'bash -s' < exec-start-dos-test-$client_num.sh)
    let client_num=$client_num+1
    if [[ $client_num -gt ${#accounts[@]} ]];then
        client_num=1
    fi 
done
echo ----- stage: wait for benchmark to end ------
sleep 10 # in start-dos-test, after keeper run, the script sleep 10s to wait for keeper ready

# Get Time Start
start_time=$(echo `date -u +%s`)
get_time_after $start_time 5
start_time_adjust=$outcom_in_sec
sleep $DURATION

sleep_time=$(echo "$DURATION+2" | bc)
sleep $sleep_time
### Get Time Stop
stop_time=$(echo `date -u +%s`)
get_time_before $stop_time 5
stop_time_adjust=$outcom_in_sec

echo ----- stage: DOS report ------
## PASS ENV
[[ $SLACK_WEBHOOK ]]&&echo "SLACK_WEBHOOK=$SLACK_WEBHOOK" >> dos-report-env.sh
[[ $DISCORD_WEBHOOK ]]&&echo "DISCORD_WEBHOOK=$DISCORD_WEBHOOK" >> dos-report-env.sh
[[ $DISCORD_AVATAR_URL ]]&&echo "DISCORD_AVATAR_URL=$DISCORD_AVATAR_URL" >> dos-report-env.sh
echo "START_TIME=${start_time}" >> dos-report-env.sh
echo "START_TIME2=${start_time_adjust}" >> dos-report-env.sh
echo "STOP_TIME=${stop_time}" >> dos-report-env.sh
echo "STOP_TIME2=${stop_time_adjust}" >> dos-report-env.sh
echo "DURATION=$DURATION" >> dos-report-env.sh                 
echo "QOUTES_PER_SECOND=$QOUTES_PER_SECOND" >> dos-report-env.sh
echo "NUM_CLIENT=$NUM_CLIENT" >> dos-report-env.sh
echo "CLUSTER_VERSION=$testnet_ver" >> dos-report-env.sh

for n in "${instance_name[@]}"
do
    printf instances "%s %s" $instances $n
done
echo "INSTANCES=$instances" >> dos-report-env.sh

ret_dos_report=$(exec ./dos-report.sh)
echo $ret_dos_report

echo ----- stage: printout run log ------
if [[ "$PRINT_LOG" == "true" ]];then
	ret_log=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@${instance_ip[0]} 'cat /home/sol/start-dos-test.nohup')
fi
echo ----- stage: upload logs ------
sleep 1200 #delay for log to be ready
source generate-exec-upload-logs.sh
for sship in "${instance_ip[@]}"
do
    ret_pre_build=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship 'bash -s' < exec-start-upload-logs.sh)
done

sleep 10
if [[ "$KEEP_INSTANCES" != "true" ]];then
    echo ----- stage: delete instances ------
    delete_machines
fi

exit 0

# echo ----- stage: printout run log ------
# if [[ "$PRINT_LOG" == "true" ]];then
# 	ret_log=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@${instance_ip[0]} 'cat /home/sol/start-dos-test.nohup')
# fi
