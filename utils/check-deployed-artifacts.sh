#!/bin/zsh

cast call --rpc-url $RPC_URL $SAFE_ADDRESS "getThreshold()(uint256)"
cast call --rpc-url $RPC_URL $SAFE_ADDRESS "getOwners()(address[])"
cast call --rpc-url $RPC_URL $SIMPLE_CONTRACT_ADDRESS "getStoredBlockNumber()"
