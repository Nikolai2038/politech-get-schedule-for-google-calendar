#!/bin/bash

# Exit on any error
set -e

source "./0_env.sh"

curl 'https://my.spbstu.ru/home/profile/' \
    -X POST \
    -H "X-CSRFToken: ${CSRF_TOKEN}" \
    -H "Cookie: csrftoken=${CSRF_TOKEN}" \
    --data-raw "{\"parameter\":1,\"group_name\":\"\u0432${GROUP_NAME}\",\"today_date\":\"${WEEK_FIRST_DAY}\"}" \
    | jq > "./data/1.json"
