#!/bin/zsh

curl -s -X GET https://api.safe.global/tx-service/sep/api/v1/safes/$SAFE_ADDRESS/multisig-transactions/ \
    -H "accept: application/json" \
    -H "content-type: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY" | python3 -m json.tool
