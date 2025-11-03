#!/bin/zsh

value=$(cast call --rpc-url $RPC_URL $SIMPLE_CONTRACT_ADDRESS --data "0xad3d7dd7")

cast --to-dec $value
