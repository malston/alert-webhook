#!/usr/bin/env bash

export GMAIL_FROM="marktalston\@gmail.com"
export PORT="9090"

LOG_DIR=${PWD}/log
mkdir -p ${LOG_DIR}

killall alert-webhook
rm alert-webhook
make build

./alert-webhook >> ${LOG_DIR}/alert-webhook.stdout.log \
    2>> ${LOG_DIR}/alert-webhook.stderr.log &

for i in {1..5}; do
    sleep 2
    curl -v --data "@assets/alerts.json" http://127.0.0.1:9090/webhook
done
