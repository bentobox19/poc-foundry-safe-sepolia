#!/bin/zsh

## PROPOSAL NONCE
json=$(curl -s -X GET https://api.safe.global/tx-service/sep/api/v1/safes/$SAFE_ADDRESS/ \
    -H "Accept: application/json" \
    -H "content-type: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY")

nonce=$(echo "$json" | awk -F'"nonce":"' '{print $2}' | sed 's/".*//')

export PROPOSAL_NONCE=$nonce

echo "PROPOSAL_NONCE: "$PROPOSAL_NONCE

## SAFE TX HASH
safe_tx_hash=$(cast call $SAFE_ADDRESS "getTransactionHash(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256)" \
  $SIMPLE_CONTRACT_ADDRESS \
  0 \
  "0x8ceb50ab" \
  0 \
  0 \
  0 \
  0 \
  "0x0000000000000000000000000000000000000000" \
  "0x0000000000000000000000000000000000000000" \
  $PROPOSAL_NONCE \
  --rpc-url $RPC_URL)

export SAFE_TX_HASH=$safe_tx_hash

echo "SAFE_TX_HASH: "$SAFE_TX_HASH

## Broadcast the proposal
curl -X POST https://api.safe.global/tx-service/sep/api/v2/safes/$SAFE_ADDRESS/multisig-transactions/ \
    -H "Accept: application/json" \
    -H "content-type: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY" \
    -d '{
  "to": "'$SIMPLE_CONTRACT_ADDRESS'",
  "nonce": "'$PROPOSAL_NONCE'",
  "sender": "'$WALLET_ADDRESS_1'",
  "contractTransactionHash": "'$SAFE_TX_HASH'",
  "value": "0",
  "data": "0x8ceb50ab",
  "operation": 0,
  "safeTxGas": 0,
  "baseGas": 0,
  "gasPrice": 0,
  "gasToken": "0x0000000000000000000000000000000000000000",
  "refundReceiver": "0x0000000000000000000000000000000000000000",
  "signatures": []
}'
