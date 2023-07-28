#!/bin/sh
# script to find strings withing all files inside a certain directory,
# Both directory path and string to find are parsed as arguments.
# Author: Pavly Farag

set -e
set -u

# Checking that number of arguments >= 2
if [ $# -lt 2 ]
then
    echo "You need to enter filesdir and searchstr arguments"
    exit 1
fi

filesdir=$1
searchstr=$2

# Checking that filesdir is a real directory in the filesystem:
if ! [ -d ${filesdir} ]
then
    echo "filesdir is not a valid directory in the filesystem, or you don't have access to it."
    exit 1
fi
numOfFiles=$(find  ${filesdir} -type f | wc -l)
noOfMatches=$(grep ${searchstr} -r ${filesdir} | wc -l)
echo "The number of files are ${numOfFiles} and the number of matching lines are ${noOfMatches}"
