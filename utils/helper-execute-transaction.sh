#!/bin/zsh

## Make sure the signatures are sorted by their index
local all_sig=""

for i in {1..5}; do
  sig_var="SIGNATURE_${i}"
  # Check if the variable is set and non-empty
  if [[ -n ${(P)sig_var} ]]; then
    all_sig="${all_sig}${(P)sig_var#0x}"
  fi
done

signatures="0x${all_sig}"

# Execute the actual transaction.
# Notice that the account #0 will send the transaction,
# meaning that given the signatures, anybody can just trigger it.
export private_key_0=$(cast wallet private-key --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/0")

cast send \
  --rpc-url $RPC_URL \
  --private-key $private_key_0 \
  $SAFE_ADDRESS \
  "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" \
  $SIMPLE_CONTRACT_ADDRESS \
  0 \
  "0x8ceb50ab" \
  0 \
  0 \
  0 \
  0 \
  "0x0000000000000000000000000000000000000000" \
  "0x0000000000000000000000000000000000000000" \
  $signatures
