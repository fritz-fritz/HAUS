#!/bin/bash

i=0
for var in "$@"
do
	declare "MAC${i}=$var"
	let i++
done

for (( count=0 ; count < $i ; count++ ))
do
	var="MAC$count"
	string=$string"hcitool info ${!var}"
	if (( $count < $i - 1 )); then string=$string"; "; fi
done

eval $string 2> /dev/null | grep "Device Name:" | sed 's/.*Name: //' | awk 'BEGIN{FS="\n|\r"; RS="\n\n"; ORS=""; header = "0"}; { if ( header == "0" ) if ( $0 != "" ) {print "Occupied By:\n"; header = "1"}; print $0}; END{ if ( NF < 1 ) print "No one is home\n"}' | sed "s/'.*$//" | sed 's/ iPhone.*$//'

