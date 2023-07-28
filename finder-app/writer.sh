#!/bin/sh
# script to write string into files
# Author: Pavly Farag

set -e
set -u

# Checking that number of arguments >= 2
if [ $# -lt 2 ]
then
    echo "You need to enter numfiles and writestr arguments"
    exit 1
fi
writefile=$1
writestr=$2

mkdir -p $(dirname ${writefile})
echo $writestr > ${writefile}
