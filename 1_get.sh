#!/bin/bash

# Exit on any error
set -e

# ========================================
# Import user's variables
# ========================================
if [ ! -f ".env" ]; then
    echo "Create \".env\" file from \".env.example\" and change variables for your needs!" >&2
fi
# shellcheck source=.env
source <(sed -E 's/\r$//;s/^\s*([^#].*?)=(.+?)\s*$/export \1=\2/' ".env") > /dev/null
# ========================================

curl 'https://my.spbstu.ru/home/profile/' \
    -X POST \
    -H "X-CSRFToken: ${CSRF_TOKEN}" \
    -H "Cookie: csrftoken=${CSRF_TOKEN}" \
    --data-raw "{\"parameter\":1,\"group_name\":\"\u0432${GROUP_NAME}\",\"today_date\":\"${WEEK_FIRST_DAY}\"}" \
    | jq > "./data/${WEEK_FIRST_DAY}.json"
