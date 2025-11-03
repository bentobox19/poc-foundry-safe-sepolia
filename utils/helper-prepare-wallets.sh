#!/bin/zsh

unsorted_pairs=()
for i in {1..5}; do
    address=$(cast wallet address --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/$i") || { echo "Error deriving address for index $i"; exit 1; }
    unsorted_pairs+=("$address $i")
done

sorted_pairs=()
while IFS= read -r line; do
    sorted_pairs+=("$line")
done < <(printf '%s\n' "${unsorted_pairs[@]}" | sort -k1)

counter=1
for pair in $sorted_pairs; do
    address=$(echo "$pair" | awk '{print $1}')
    index=$(echo "$pair" | awk '{print $2}')

    private_key=$(cast wallet private-key --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/$index")

    export "WALLET_ADDRESS_$counter"="$address"
    export "PRIVATE_KEY_$counter"="$private_key"

    ((counter++))
done
