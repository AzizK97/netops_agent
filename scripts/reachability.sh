#!/bin/bash

PREFIX=clab-data_center
declare -A IP=( [host1]=192.168.1.10 [host2]=192.168.2.10 [host3]=192.168.3.10
                [host4]=192.168.3.11 [host5]=192.168.1.11 [host6]=192.168.4.10 )
HOSTS=(host1 host2 host3 host4 host5 host6)
fail=0

printf "%-7s" ""; for d in "${HOSTS[@]}"; do printf "%-7s" "$d"; done; echo
for s in "${HOSTS[@]}"; do
  printf "%-7s" "$s"
  for d in "${HOSTS[@]}"; do
    if [[ $s == $d ]]; then printf "%-7s" "-"; continue; fi
    if docker exec $PREFIX-$s ping -c1 -W1 -q ${IP[$d]} >/dev/null 2>&1; then
      printf "%-7s" "ok"
    else
      printf "%-7s" "FAIL"; fail=1
    fi
  done; echo
done
exit $fail
