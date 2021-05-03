#!/usr/bin/env bash

if [[ ! $1 ]]; then
  echo "no host provided, usage: $0 http://host"; exit 1
fi

HOST="$1"
TIMEOUT=${2:-120}
STATUS=

echo "checking $HOST status..."
for elapsed in $(seq 0 "$TIMEOUT"); do
  STATUS="$(curl -kIsL -o /dev/null -w "%{http_code}" --connect-timeout 2 "$HOST")"

  if [[ $STATUS -eq 200 ]]; then
    echo "ready, page returned: $STATUS"
    exit 0
  fi

  echo "not ready, page returned: $STATUS"
  echo "elapsed: $elapsed/$TIMEOUT"
  sleep 1
done

echo "ERROR: velum did not reach ready status in ${TIMEOUT}s"; exit 1
