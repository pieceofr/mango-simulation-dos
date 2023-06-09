#!/usr/bin/env bash
## start-dos-test.sh
## arg1: account file to use
## arg2: RUN_KEEPER
set -ex
# shellcheck source=/dev/null
source $HOME/.profile
# shellcheck source=/dev/null
source $HOME/env-artifact.sh
#############################
[[ ! "$CLUSTER" ]] && echo no CLUSTER && exit 1
[[ ! "$SOLANA_METRICS_CONFIG" ]] && echo no SOLANA_METRICS_CONFIG ENV && exit 1
[[ ! "$RUST_LOG" ]] && RUST_LOG=info
[[ ! "$DURATION" ]] && echo no DURATION && exit 1
[[ ! "$QOUTES_PER_SECOND" ]] && echo no QOUTES_PER_SECOND && exit 1
[[ ! "$ENDPOINT" ]]&& echo "No ENDPOINT" && exit 1
[[ ! "$AUTHORITY_FILE" ]] && echo no AUTHORITY_FILE && exit 1
[[ ! "$ID_FILE" ]] && echo no ID_FILE && exit 1
[[ ! "$1" ]]&& echo no ACCOUNT_FILE as arg1 && exit 1 || ACCOUNT_FILE="$1"
[[ ! "$2" ]]&& echo no RUN_KEEPER as arg2 && exit 1 || RUN_KEEPER="$2"


#### metrics env ####
configureMetrics() {
  [[ -n $SOLANA_METRICS_CONFIG ]] || return 0

  declare metricsParams
  IFS=',' read -r -a metricsParams <<< "$SOLANA_METRICS_CONFIG"
  for param in "${metricsParams[@]}"; do
    IFS='=' read -r -a pair <<< "$param"
    if [[ ${#pair[@]} != 2 ]]; then
      echo Error: invalid metrics parameter: "$param" >&2
    else
      declare name="${pair[0]}"
      declare value="${pair[1]}"
      case "$name" in
      host)
        export INFLUX_HOST="$value"
        echo INFLUX_HOST="$INFLUX_HOST" >&2
        ;;
      db)
        export INFLUX_DATABASE="$value"
        echo INFLUX_DATABASE="$INFLUX_DATABASE" >&2
        ;;
      u)
        export INFLUX_USERNAME="$value"
        echo INFLUX_USERNAME="$INFLUX_USERNAME" >&2
        ;;
      p)
        export INFLUX_PASSWORD="$value"
        echo INFLUX_PASSWORD="********" >&2
        ;;
      *)
        echo Error: Unknown metrics parameter name: "$name" >&2
        ;;
      esac
    fi
  done
}
#### export ENVs ####
export CLUSTER=$CLUSTER
export RUST_LOG=$RUST_LOG
export ENDPOINT_URL=$ENDPOINT
## Prepare Metrics Env
configureMetrics
## Prepare Log Directory
if [[ ! -d "$HOME/$HOSTNAME" ]];then
	echo "NO $HOME/$HOSTNAME found" && exit 1
fi

sleep 10

echo --- stage: Run Solana-simulation -----
# benchmark exec in $HOME Directory
cd $HOME
b_cluster_ep=$ENDPOINT
b_validator_id_f="$HOME/$VALIDATOR_ID_FILE"
b_auth_f="$HOME/$AUTHORITY_FILE"
b_acct_f="$HOME/$ACCOUNT_FILE"
b_id_f="$HOME/$ID_FILE"
b_mango_cluster=$CLUSTER
b_duration=$DURATION
b_q=$QOUTES_PER_SECOND
b_tx_save_f="$HOME/$HOSTNAME/TLOG.csv"
b_block_save_f="$HOME/$HOSTNAME/BLOCK.csv"
b_error_f="$HOME/$HOSTNAME/error.txt"

echo $(pwd)
echo --- start of benchmark $(date)

args=(
  --url $b_cluster_ep
  --identity $b_validator_id_f
  --accounts $b_acct_f
  --mango $b_id_f
  --mango-cluster $b_mango_cluster
  --duration $b_duration
  --quotes-per-second $b_q
  --block-data-save-file $b_block_save_f
  --markets-per-mm 5
)

if [[ "$SAVE_TRANSACTIONS_LOG" == "true" ]]; then
  args+=(--transaction-save-file $b_tx_save_f)
fi

if [[ "$RUN_KEEPER" == "true" ]] ;then
    args+=(--keeper-authority $b_auth_f)
fi

ret_bench=$(./mango-simulation "${args[@]}" 2> $b_error_f &)
echo --- stage: tar log files ---
if [[ "$SAVE_TRANSACTIONS_LOG" == "true" ]]; then
  tar --remove-files -czf "${b_tx_save_f}.tar.gz" ${b_tx_save_f} || true
fi
[[ -f "$HOME/start-dos-test.nohup" ]] && cp "$HOME/start-dos-test.nohup" "$HOME/$HOSTNAME" || true
echo --- end of benchmark $(date)
exit 0

