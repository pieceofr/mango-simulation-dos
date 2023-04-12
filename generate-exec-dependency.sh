# add git repo to exe-start-template
echo "git clone $GIT_REPO" >> exec-start-template.sh
echo "cd mango_bencher-dos-test" >> exec-start-template.sh
echo "git checkout $BUILDKITE_BRANCH" >> exec-start-template.sh
echo "cd ~" >> exec-start-template.sh
echo 'cp ~/mango_bencher-dos-test/start-build-dependency.sh .' >> exec-start-template.sh
echo 'cp ~/mango_bencher-dos-test/start-dos-test.sh .' >> exec-start-template.sh


echo ----- stage: create exec-start-build-dependency-build.sh ------
# the only difference is $BUILD_MANGO_BENCHER
[[ ! "$CHANNEL" ]]&& CHANNEL=edge
cat exec-start-template.sh > exec-start-build-dependency-build.sh
echo "export CHANNEL=$CHANNEL" >> exec-start-build-dependency-build.sh
echo "export BUILD_MANGO_BENCHER=true" >> exec-start-build-dependency-build.sh
echo "export MANGO_BENCHER_REPO=$MANGO_BENCHER_REPO" >> exec-start-build-dependency-build.sh
echo "export MANGO_BENCHER_BRANCH=$MANGO_BENCHER_BRANCH" >> exec-start-build-dependency-build.sh
echo "export MANGO_CONFIGURE_REPO=$MANGO_CONFIGURE_REPO" >> exec-start-build-dependency-build.sh
echo "export MANGO_CONFIGURE_BRANCH=$MANGO_CONFIGURE_BRANCH" >> exec-start-build-dependency-build.sh
echo "export BUILD_DEPENDENCY_BENCHER_DIR=$BUILD_DEPENDENCY_BENCHER_DIR" >> exec-start-build-dependency-build.sh
#echo "export BUILD_DEPENDENCY_SOLALNA_DOWNLOAD_DIR=$BUILD_DEPENDENCY_SOLALNA_DOWNLOAD_DIR" >> exec-start-build-dependency-build.sh
echo "export BUILD_DEPENDENCY_CONFIGURE_DIR=$BUILD_DEPENDENCY_CONFIGURE_DIR" >> exec-start-build-dependency-build.sh
echo "export AUTHORITY_FILE=$AUTHORITY_FILE" >> exec-start-build-dependency-build.sh
echo "export ID_FILE=$ID_FILE" >> exec-start-build-dependency-build.sh
echo "export ACCOUNTS=\"$ACCOUNTS\"" >> exec-start-build-dependency-build.sh # Notice without double quoate mark, it won't be parse into array
echo 'exec  ./start-build-dependency.sh > start-build-dependency.log' >> exec-start-build-dependency-build.sh # should be sequential
chmod +x exec-start-build-dependency-build.sh

echo ----- stage: create exec-start-build-dependency-download.sh ------
# the only difference is $BUILD_MANGO_BENCHER
[[ ! "$CHANNEL" ]]&& CHANNEL=edge
cat exec-start-template.sh > exec-start-build-dependency-download.sh
echo "export CHANNEL=$CHANNEL" >> exec-start-build-dependency-download.sh
echo "export BUILD_MANGO_BENCHER=false" >> exec-start-build-dependency-download.sh
echo "export MANGO_BENCHER_REPO=$MANGO_BENCHER_REPO" >> exec-start-build-dependency-download.sh
echo "export MANGO_BENCHER_BRANCH=$MANGO_BENCHER_BRANCH" >> exec-start-build-dependency-download.sh
echo "export MANGO_CONFIGURE_REPO=$MANGO_CONFIGURE_REPO" >> exec-start-build-dependency-download.sh
echo "export MANGO_CONFIGURE_BRANCH=$MANGO_CONFIGURE_BRANCH" >> exec-start-build-dependency-download.sh
echo "export BUILD_DEPENDENCY_BENCHER_DIR=$BUILD_DEPENDENCY_BENCHER_DIR" >> exec-start-build-dependency-download.sh
#echo "export BUILD_DEPENDENCY_SOLALNA_DOWNLOAD_DIR=$BUILD_DEPENDENCY_SOLALNA_DOWNLOAD_DIR" >> exec-start-build-dependency-download.sh
echo "export BUILD_DEPENDENCY_CONFIGURE_DIR=$BUILD_DEPENDENCY_CONFIGURE_DIR" >> exec-start-build-dependency-download.sh
echo "export AUTHORITY_FILE=$AUTHORITY_FILE" >> exec-start-build-dependency-download.sh
echo "export ID_FILE=$ID_FILE" >> exec-start-build-dependency-download.sh
echo "export ACCOUNTS=\"$ACCOUNTS\"" >> exec-start-build-dependency-download.sh # Notice without double quoate mark, it won't be parse into array
echo 'exec  ./start-build-dependency.sh > start-build-dependency.log' >> exec-start-build-dependency-download.sh # should be sequential
chmod +x exec-start-build-dependency-download.sh
