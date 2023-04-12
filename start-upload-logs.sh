#!/usr/bin/env bash
set -x
source ~/.bashrc
source ~/.profile
cd ~
upload_log_folder() {
	gsutil cp -r $1 gs://mango_bencher-dos-log/

}


[[ ! "$BUILD_DEPENDENCY_BENCHER_DIR" ]]&& echo no BUILD_DEPENDENCY_BENCHER_DIR && exit 1
[[ ! "$BUILD_DEPENDENCY_CONFIGURE_DIR" ]]&& echo no BUILD_DEPENDENCY_CONFIGURE_DIR && exit 1

ls -al $HOME/$HOSTNAME  > $HOME/all-logs.out
cat all-logs.out
cd $HOME
# upload_file $BUILD_DEPENDENCY_CONFIGURE_DIR/$HOSTNAME-keeper.log Log
# upload_file $BUILD_DEPENDENCY_BENCHER_DIR/target/release/$HOSTNAME-TLOG.csv Log
# upload_file $BUILD_DEPENDENCY_BENCHER_DIR/target/release/$HOSTNAME-BLOCK.csv Log
# upload_file $BUILD_DEPENDENCY_BENCHER_DIR/target/release/$HOSTNAME-error.txt Log

upload_log_folder $HOME/$HOSTNAME
