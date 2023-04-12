#!/usr/bin/env bash
## env
set -ex
## Check ENV
# to avoid name conflict between executable and folder
# rename from mango-simulation to mango_simulation
MANGO_BENCHER_FOLDER=mango_simulation
[[ ! "$BUILD_DEPENDENCY_BENCHER_DIR" ]]&& BUILD_DEPENDENCY_BENCHER_DIR="$HOME/$MANGO_BENCHER_FOLDER"
[[ ! "$BUILD_DEPENDENCY_CONFIGURE_DIR" ]]&& BUILD_DEPENDENCY_CONFIGURE_DIR="$HOME/configure_mango"
[[ ! "$MANGO_BENCHER_REPO" ]]&&  echo no MANGO_BENCHER_REPO=$MANGO_BENCHER_REPO&& exit 1
[[ ! "$MANGO_BENCHER_BRANCH" ]]&&  echo no MANGO_BENCHER_BRANCH=$MANGO_BENCHER_BRANCH&& exit 1
[[ ! "$ACCOUNTS" ]]&&  echo no ACCOUNTS=$ACCOUNTS&& exit 1
[[ ! "$AUTHORITY_FILE" ]] &&  echo no AUTHORITY_FILE=$AUTHORITY_FILE&& exit 1
[[ ! "$ID_FILE" ]] &&  echo no ID_FILE=$ID_FILE&& exit 1
[[ ! "$CHANNEL" ]]&& CHANNEL=stable && echo No CHANNEL , use $CHANNEL
[[ ! "$RUST_VER" ]]&& RUST_VER=default && echo No RUST_VER use $RUST_VER 

# Printout Env
[[ -f "env.output" ]]&& rm env.output
echo BUILD_MANGO_BENCHER: $BUILD_MANGO_BENCHER >> env.output
echo BUILD_DEPENDENCY_BENCHER_DIR: $BUILD_DEPENDENCY_BENCHER_DIR >> env.output
echo BUILD_DEPENDENCY_CONFIGURE_DIR: $BUILD_DEPENDENCY_CONFIGURE_DIR >> env.output
echo MANGO_BENCHER_REPO: $MANGO_BENCHER_REPO >> env.output
echo MANGO_BENCHER_BRANCH: $MANGO_BENCHER_BRANCH >> env.output
echo ACCOUNTS: $ACCOUNTS >> env.output
echo AUTHORITY_FILE: $AUTHORITY_FILE >> env.output
echo ID_FILE: $ID_FILE >> env.output
echo CHANNEL: $CHANNEL >> env.output
echo RUST_VER: $RUST_VER >> env.output


## Download key files from gsutil
download_file() {
	for retry in 0 1
	do
		if [[ $retry -gt 1 ]];then
			break
		fi
		gsutil cp  gs://mango_bencher-dos/$1 ./
		if [[ ! -f "$1" ]];then
			echo "NO $1 found, retry"
		else
			break
		fi
	done
}
upload_file() {
	gsutil cp  $1 gs://mango_bencher-dos/$2
}
## preventing lock-file build fail, 
## also need to disable software upgrade in image
sudo fuser -vki -TERM /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend || true
sudo dpkg --configure -a
sudo apt update
## pre-install and rust version
sudo apt-get install -y libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler
rustup default stable
rustup update

cd $HOME
[[ -d "$BUILD_DEPENDENCY_BENCHER_DIR" ]]&& rm -rf $BUILD_DEPENDENCY_BENCHER_DIR
# clone mango_bencher and mkdir dep dir
git clone $MANGO_BENCHER_REPO $MANGO_BENCHER_FOLDER

cd $BUILD_DEPENDENCY_BENCHER_DIR

if  [[ "$BUILD_MANGO_BENCHER" == "true" ]];then
    git checkout $MANGO_BENCHER_BRANCH
	cargo build --release
	# cp from BUILD_DEPENDENCY_BENCHER_DIR to HOME
	cp $BUILD_DEPENDENCY_BENCHER_DIR/target/release/mango-simulation $HOME
	chmod +x $HOME/mango-simulation
	upload_file $HOME/mango-simulation
else
	# download from bucket
	cd $HOME
	download_file mango-simulation
	[[ ! -f "$HOME/mango-simulation" ]] && echo no mango-simulation downloaded && exit 1
fi

# pre-requicy by configure_mango
cd $HOME
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g typescript
sudo npm install -g ts-node
sudo npm install -g yarn
# download configure_mango repo
git clone $MANGO_CONFIGURE_REPO
cd $BUILD_DEPENDENCY_CONFIGURE_DIR
# warning package-lock.json found. 
# Your project contains lock files generated by tools other than Yarn. 
# It is advised not to mix package managers in order to avoid resolution inconsistencies caused by unsynchronized lock files.
# To clear this warning, remove package-lock.json.
# Memo by author: use yarn instead of npm install
rm -f package-lock.json
git checkout $MANGO_CONFIGURE_BRANCH
yarn install

echo --- stage: Start To Download Files
cd $BUILD_DEPENDENCY_CONFIGURE_DIR
download_file $AUTHORITY_FILE
[[ ! -f "$AUTHORITY_FILE" ]]&&echo no $AUTHORITY_FILE file && exit 1
cp $AUTHORITY_FILE $HOME
download_file $ID_FILE
[[ ! -f "$ID_FILE" ]]&&echo no $ID_FILE file && exit 1
cp $ID_FILE $HOME

cd $BUILD_DEPENDENCY_BENCHER_DIR
echo $ACCOUNTS
download_accounts=( $ACCOUNTS )
for acct in ${download_accounts[@]}
do
  echo --- start to download $acct
  download_file $acct
  cp $acct $HOME
done

echo --- stage: Start refunding clients accounts
cd $BUILD_DEPENDENCY_CONFIGURE_DIR
for acct in ${download_accounts[@]}
do
  ts-node refund_users.ts "${HOME}/$acct" > out.log 2>1 || true
  if [ $? -ne 0 ]; then
    echo --- refund failed for $acct
    cat out.log
  fi
done

cd $HOME 
download_file configure-metrics.sh
[[ ! -f "$HOME/configure-metrics.sh" ]]&&echo no configure-metrics.sh file && exit 1
chmod +x configure-metrics.sh
download_file dos-metrics-env.sh
[[ ! -f "$HOME/dos-metrics-env.sh" ]]&&echo no dos-metrics-env.sh file && exit 1
download_file dos-report-env.sh
[[ ! -f "$HOME/dos-report-env.sh" ]]&&echo no dos-report-env.sh file && exit 1
exit 0

