#!/bin/bash

echo "run postman scripts"
IFS='
'
for line in `cat caselist.csv`
do
	#echo $line
	#echo $line | xargs -t newman run
	echo "newman run "${line} | cat >> test1.sh
	
	#sleep 3
done

./test1.sh

