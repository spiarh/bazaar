#!/usr/bin/env bash

OOM="$(grep 'Memory cgroup out of memory' messages.txt | grep -oE '\(.*)'|sed 's/(//;s/)//')"

echo "$OOM" |
awk '{ count[$0]++ }
END {printf("%-20s%s\n","Process","Count") ;
for(ind in count)
{ printf("%-20s%d\n",ind,count[ind]); }
}'
