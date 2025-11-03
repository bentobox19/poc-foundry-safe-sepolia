#!/bin/zsh

if [[ $# -ne 1 ]] || [[ ! "$1" =~ ^[1-5]$ ]]; then
  echo "Usage: $0 <signer_number> (1-5)"
  exit 1
fi

SIGNER_NUM=$1

PRIVATE_KEY_VAR="PRIVATE_KEY_${SIGNER_NUM}"
SIGNATURE_VAR="SIGNATURE_${SIGNER_NUM}"

# SIGNATURE_{$SIGNER_NUM}
signature=$(cast wallet sign --private-key ${(P)PRIVATE_KEY_VAR} --no-hash $SAFE_TX_HASH)

export "${SIGNATURE_VAR}=${signature}"

# Submit
curl -X POST "https://api.safe.global/tx-service/sep/api/v1/multisig-transactions/$SAFE_TX_HASH/confirmations/" \
  -H "Accept: application/json" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer $SAFE_API_KEY" \
  -d "{\"signature\": \"$signature\"}"
