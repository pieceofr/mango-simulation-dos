
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
## Directory settings
dos_program_dir=$(pwd)
BUILD_DEPENDENCY_BENCHER_DIR=/home/sol/mango_simulation
BUILD_DEPENDENCY_CONFIGURE_DIR=/home/sol/configure_mango

# Prepare build binary in Agent

sudo fuser -vki -TERM /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend || true
sudo dpkg --configure -a
sudo apt update
## pre-install and rust version
sudo apt-get install -y libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler
echo $dos_program_dir
. "$HOME/.profile"
rustup default stable
rustup update



exit 0