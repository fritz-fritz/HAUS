#!/bin/bash
testnum='^[0-9]+$'

if [ $# -eq 0 ]
  then
    echo "Error: No arguments supplied"
    exit 1
elif (( $# > 1 ))
  then
    echo "Error: Too many arguments"
    exit 1
elif [[ "$@" -eq 0 ]]
  then
    echo "Error: '0' is an invalid argument"
    exit 1
elif ! [[ "$@" =~ $testnum ]]
  then
    echo "Error: Argument is not a number"
    exit 1
fi

for (( j=0 ; j < $1 ; j++ ))
do
	string=$string" \$MAC${j}"
done

echo $string
