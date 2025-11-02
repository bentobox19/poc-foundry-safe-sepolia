# Foundry, Sepolia and Safe Wallets

A study on Safe wallet multisig operation.

<!-- MarkdownTOC -->

- Disclaimer
- Preliminaires: Wallets
  - New seedphrase
  - Funding from an existing wallet
  - Derive 5 wallets and send them funds
  - Sort the wallets and private keys
- Side Note: If you want to operate in a local fork of Sepolia
- Deploying safe wallet and simple contract artifacts
  - Finding the addresses in Sepolia
  - Deploy the safe wallet
  - Check - Interact with the safe wallet contract
  - Deploy a simple contract for the safe wallet to interact with
  - Check - Interact with deployed contract
- Multisig transaction
  - Goal
  - Safe transaction service
  - Generate a proposal
    - Compute transaction hash
    - Send the multisig proposal
    - Check - Proposal sent
    - Sign and send a confirmation
    - Check - Proposal status
    - Sample of the status response
  - Execute the transaction
    - Test the value at the simple contract

<!-- /MarkdownTOC -->

## Disclaimer

This project is provided solely for educational and study purposes, demonstrating
concepts related to multisig wallet operations. It is **not recommended for real-world
use**, production environments, or handling actual cryptocurrencies. The code and
related materials are offered "as-is" without any warranties of any kind, express
or implied, including but not limited to the accuracy, completeness, safety,
reliability, or performance of the software. The contributors disclaim all liability
for any damages, losses, or issues arising from its use. Always conduct your own
testing and use at your own risk in a controlled, non-production environment.

## Preliminaires: Wallets

Where we create a new seed phrase, new wallets, and funding them from an existing account. All of this using `cast`.

### New seedphrase

````bash
cast wallet new-mnemonic

# Ledger has a derivation path different from cast and MetaMask
## MetaMask & cast: m/44'/60'/0'/0/x
## Ledger Live: m/44'/60'/x'/0/0
export MNEMONIC="<MNEMONIC>"

cast wallet address --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/0"
````

### Funding from an existing wallet

````bash
export FUNDING_ADDR_MNEMONIC="<FUNDING_ADDR_MNEMONIC>"

export FUNDING_ADDR_PRIVATE_KEY=$(cast wallet private-key --mnemonic "$FUNDING_ADDR_MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/0")

export RPC_URL="https://eth-sepolia.g.alchemy.com/v2/<ALCHEMY_API_KEY>"

# Send 1 ETH to $ADDRESS_0
cast send $ADDRESS_0 --rpc-url $RPC_URL --value 1ether --private-key $FUNDING_ADDR_PRIVATE_KEY

# Verify the transfer
cast balance $ADDRESS_0
````

### Derive 5 wallets and send them funds

````bash
export PRIVATE_KEY_0=$(cast wallet private-key --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/0")
for i in {1..5}; do
    wallet_address=$(cast wallet address --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/$i")
    cast send $wallet_address \
        --rpc-url $RPC_URL \
        --value 0.001ether \
        --private-key $PRIVATE_KEY_0
done

# Check the balances of all your derivated accounts
for i in {0..5}; do
    address=$(cast wallet address --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/$i")
    balance=$(cast balance --rpc-url $RPC_URL "$address")
    echo "Address: $address Balance: $balance"
done
````

### Sort the wallets and private keys

We need the signatures sorted by their addresses

````bash
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
````

## Side Note: If you want to operate in a local fork of Sepolia

````bash
export RPC_URL="https://eth-sepolia.g.alchemy.com/v2/<ALCHEMY_API_KEY>"

anvil --fork-url $RPC_URL --port 8545 --chain-id 11155111

cast balance $WALLET_ADDRESS_1 --rpc-url http://localhost:8545
1000000000000000
````

## Deploying safe wallet and simple contract artifacts

### Finding the addresses in Sepolia

We want to find the addresses in Sepolia for Safe's Singleton and Factory

- Source of Truth
  - https://github.com/safe-global/safe-deployments?tab=readme-ov-file#deployments-overview
- 1.4.1
  - https://contractscan.xyz/bundle?name=Safe+1.4.1&addresses=0xfd0732dc9e303f09fcef3a7388ad10a83459ec99,0x9b35af71d77eaf8d7e40252370304687390a1a52,0x38869bf66a61cf6bdb996a6ae40d5853fd43b526,0x9641d764fc13c8b624c04430c7356c1c7c8102e2,0x41675c099f32341bf84bfc5382af534df5c7461a,0x29fcb43b46531bca003ddc8fcb67ffe91900c762,0x4e1dcf7ad4e460cfd30791ccc4f9c8a4f820ec67,0xd53cd0ab83d845ac265be939c57f53ad838012c9,0x3d4ba2e0884aa488718476ca2fb8efc291a46199,0x526643F69b81B008F46d95CD5ced5eC0edFFDaC6,0xfF83F6335d8930cBad1c0D439A841f01888D9f69,0xBD89A1CE4DDe368FFAB0eC35506eEcE0b1fFdc54
- Factory
  - https://sepolia.etherscan.io/address/0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67
- Singleton
  - https://sepolia.etherscan.io/address/0x41675c099f32341bf84bfc5382af534df5c7461a

### Deploy the safe wallet

Find the source code in this repository at `/script/DeplotSafe.sol`

````bash
forge script script/DeploySafe.s.sol --rpc-url $RPC_URL --broadcast

# See the script output
export SAFE_ADDRESS="<SAFE_ADDRESS>"
````

### Check - Interact with the safe wallet contract

````bash
cast call --rpc-url $RPC_URL $SAFE_ADDRESS "getThreshold()(uint256)"

cast call --rpc-url $RPC_URL $SAFE_ADDRESS "getOwners()(address[])"
````

### Deploy a simple contract for the safe wallet to interact with

Find the source code in this repository `/src/SimpleContract.sol`

````bash
forge create src/SimpleContract.sol:SimpleContract \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY_0 \
    --broadcast \
    --constructor-args "$SAFE_ADDRESS"

# See the script output
export SIMPLE_CONTRACT_ADDRESS="<SIMPLE_CONTRACT_ADDRESS>"
````

### Check - Interact with deployed contract

````bash
# Writing attempts will be reverted with data
## 0x118cdaa70000000000000000000000000000000000000000000000000000000000000000
## `OwnableUnauthorizedAccount(address)`
cast call --rpc-url $RPC_URL $SIMPLE_CONTRACT_ADDRESS --private-key $PRIVATE_KEY_0 "storeBlockNumber()"
cast call --rpc-url $RPC_URL $SIMPLE_CONTRACT_ADDRESS --private-key $PRIVATE_KEY_0 --data "0x8ceb50ab"

cast call --rpc-url $RPC_URL $SIMPLE_CONTRACT_ADDRESS "getStoredBlockNumber()"
cast call --rpc-url $RPC_URL $SIMPLE_CONTRACT_ADDRESS --data "0xad3d7dd7"
````

## Multisig transaction

### Goal

We want our safe wallet to talk to this deployed `SimpleContract`, particularly to `storeBlockNumber()`

### Safe transaction service

````bash
# Set the key as an environment variable
export SAFE_API_KEY="<SAFE_API_KEY>
````

Documentation links

- Getting the API key
  - https://docs.safe.global/core-api/how-to-use-api-keys
  - https://developer.safe.global/login
- Safe transaction service
  - https://docs.safe.global/advanced/smart-account-supported-networks
  - https://safe-transaction-sepolia.safe.global/
  - https://docs.safe.global/core-api/transaction-service-reference/sepolia

Test the Endpoint - Get the safes owned by `$WALLET_ADDRESS_3`

````bash
curl -X GET https://api.safe.global/tx-service/sep/api/v1/owners/$WALLET_ADDRESS_3/safes/ \
    -H "Accept: application/json" \
    -H "content-type: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY"
````

### Generate a proposal

Documentation links

- https://api.safe.global/tx-service/sep#/transactions/
- https://docs.safe.global/sdk/api-kit/guides/propose-and-confirm-transactions


We need the nonce - Take it from the response to this API request

````bash
curl -X GET https://api.safe.global/tx-service/sep/api/v1/safes/$SAFE_ADDRESS/ \
    -H "Accept: application/json" \
    -H "content-type: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY"

export PROPOSAL_NONCE=0
````

#### Compute transaction hash

There are several ways and tools to do this

- https://github.com/OpenZeppelin/safe-utils
- https://github.com/pcaversaccio/safe-tx-hashes-util

We can always use the function `ISafe.getTransactionHash()` though

- https://docs.safe.global/reference-smart-account/transactions/getTransactionHash

````bash
cast call $SAFE_ADDRESS "getTransactionHash(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256)" \
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
  --rpc-url $RPC_URL

export SAFE_TX_HASH="<SAFE_TX_HASH>"
````

#### Send the multisig proposal

````bash
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
````

#### Check - Proposal sent

````bash
curl -X GET https://api.safe.global/tx-service/sep/api/v2/multisig-transactions/$SAFE_TX_HASH/ \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY"
````

#### Sign and send a confirmation

````bash
cast wallet sign --private-key $PRIVATE_KEY_1 --no-hash $SAFE_TX_HASH

export SIGNATURE_1="<SIGNATURE_1>"

# Submit the confirmation
curl -X POST "https://api.safe.global/tx-service/sep/api/v1/multisig-transactions/$SAFE_TX_HASH/confirmations/" \
  -H "Accept: application/json" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer $SAFE_API_KEY" \
  -d "{\"signature\": \"$SIGNATURE_1\"}"
````

#### Check - Proposal status

````bash
curl -X GET https://api.safe.global/tx-service/sep/api/v2/multisig-transactions/$SAFE_TX_HASH/ \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY"
````

#### Sample of the status response

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "safe": "<SAFE_ADDRESS>",
      "to": "<SIMPLE_CONTRACT_ADDRESS>",
      "value": "0",
      "data": "0x8ceb50ab",
      "operation": 0,
      "gasToken": "0x0000000000000000000000000000000000000000",
      "safeTxGas": "0",
      "baseGas": "0",
      "gasPrice": "0",
      "refundReceiver": "0x0000000000000000000000000000000000000000",
      "nonce": "0",
      "executionDate": null,
      "submissionDate": "2025-10-29T23:47:50.285157Z",
      "modified": "2025-10-30T13:12:15.689163Z",
      "blockNumber": null,
      "transactionHash": null,
      "safeTxHash": "<SAFE_TX_HASH>",
      "proposer": "<WALLET_ADDRESS_1>",
      "proposedByDelegate": null,
      "executor": null,
      "isExecuted": false,
      "isSuccessful": null,
      "ethGasPrice": null,
      "maxFeePerGas": null,
      "maxPriorityFeePerGas": null,
      "gasUsed": null,
      "fee": null,
      "origin": "{}",
      "dataDecoded": null,
      "confirmationsRequired": 3,
      "confirmations": [
        {
          "owner": "<WALLET_ADDRESS_1",
          "submissionDate": "2025-10-30T13:01:53.039501Z",
          "transactionHash": null,
          "signature": "<SIGNATURE_1>",
          "signatureType": "EOA"
        },
        {
          "owner": ",WALLET_ADDRESS_2>",
          "submissionDate": "2025-10-30T13:12:15.689163Z",
          "transactionHash": null,
          "signature": "<SIGNATURE_2>",
          "signatureType": "EOA"
        }
      ],
      "trusted": true,
      "signatures": null
    }
  ],
  "countUniqueNonce": 1
}
```

### Execute the transaction

A call to the safe wallet can be made once the number of confirmations reaches the threshold.

We can always replace `cast send` with `cast call` to test the transaction

````bash
export SIGNATURES="0x${SIcast call --rpc-url $RPC_URL $SIMPLE_CONTRACT_ADDRESS --data "0xad3d7dd7"GNATURE_1#0x}${SIGNATURE_2#0x}${SIGNATURE_3#0x}"

cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY_0 $SAFE_ADDRESS "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" $SIMPLE_CONTRACT_ADDRESS 0 "0x8ceb50ab" 0 0 0 0 "0x0000000000000000000000000000000000000000" "0x0000000000000000000000000000000000000000" $SIGNATURES
````

#### Test the value at the simple contract

````bash
cast call --rpc-url $RPC_URL $SIMPLE_CONTRACT_ADDRESS --data "0xad3d7dd7"
````

````bash
# In this example we received the response
# 0x00000000000000000000000000000000000000000000000000000000009178bf

cast --to-dec 0x9178bf
# 9533631
# Which is the block where the transaction does happen.
````
