echo ----- stage: create exec-start-dos-test-x.sh ------
# add information to exec-start-dos-test.sh
function gen_dos_test() {
    cat exec-start-template.sh > exec-start-dos-test-$1.sh
    echo "export BUILD_DEPENDENCY_CONFIGURE_DIR=$BUILD_DEPENDENCY_CONFIGURE_DIR" >> exec-start-dos-test-$1.sh
    echo "export RUST_LOG=$RUST_LOG" >> exec-start-dos-test-$1.sh
    echo "export ENDPOINT=$ENDPOINT" >> exec-start-dos-test-$1.sh
    echo "export DURATION=$DURATION" >> exec-start-dos-test-$1.sh
    echo "export QOUTES_PER_SECOND=$QOUTES_PER_SECOND" >> exec-start-dos-test-$1.sh
    echo "export ACCOUNTS=\"$ACCOUNTS\"" >>exec-start-dos-test-$1.sh # Notice without double quoate mark, it won't be parse into array
    echo "export ACCOUNT_FILE=$ACCOUNT_FILE" >> exec-start-dos-test-$1.sh
    echo "export ID_FILE=$ID_FILE" >> exec-start-dos-test-$1.sh
    echo "export AUTHORITY_FILE=$AUTHORITY_FILE" >> exec-start-dos-test-$1.sh
    echo "export CLUSTER=$CLUSTER" >> exec-start-dos-test-$1.sh
    echo "export RUN_KEEPER=$RUN_KEEPER" >> exec-start-dos-test-$1.sh # Run Keeper in first node but not in other nodes
    echo "export KEEPER_GROUP=$KEEPER_GROUP" >> exec-start-dos-test-$1.sh
    echo "export KEEPER_ENDPOINT=$KEEPER_ENDPOINT" >> exec-start-dos-test-$1.sh
    echo 'exec nohup ./start-dos-test.sh > start-dos-test.log 2>start-dos-test.nohup &' >> exec-start-dos-test-$1.sh
    chmod +x exec-start-dos-test-$1.sh
}
