# mango_bencher-dos-test
    Purpose of mango_bencher-dos-test is to use mango_bencher to do DOS test in Testnet
## Files

+ main.go : main procedure
+ generate-exec-files.sh
    - to generate files to run by CI to ssh running start-build-dependency.sh & start-dos-test.sh
    - create temporary files 
        - exec-start-build-dependency.sh : execute by CI agent (ie. buidkite) to build dependencies in remote client
+ create-instatnce.sh
    - to create google cloud machines
+ start-build-dependency.sh : script to run in remote client to build dependencies
+ start-dos-test.sh : script to run in remore client to run mango_bencher dos test




