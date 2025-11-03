# Foundry, Sepolia and Safe Wallets - Utils

<!-- MarkdownTOC -->

- Before Starting
- Requirement - Seed Phrase
- Prepare Wallets
- Deploy artifacts
- Check the Deployed Artifacts
- Multisig Operations
  - Proposal
  - Confirmations
  - Execution
- Summary

<!-- /MarkdownTOC -->

## Before Starting

These scripts are written for MacOS Zsh.

## Requirement - Seed Phrase

````bash
unset HISTFILE
export MNEMONIC="<MNEMONIC>"
export RPC_URL="https://eth-sepolia.g.alchemy.com/v2/<ALCHEMY_API_KEY>"
````

## Prepare Wallets

````bash
# Objective: Setting up the following env variables
# Assume the wallets already have funds.
# If you already have set up the variables, skip this helper.
#
## PRIVATE_KEY_1
## PRIVATE_KEY_2
## PRIVATE_KEY_3
## PRIVATE_KEY_4
## PRIVATE_KEY_5
## WALLET_ADDRESS_1
## WALLET_ADDRESS_2
## WALLET_ADDRESS_3
## WALLET_ADDRESS_4
## WALLET_ADDRESS_5

# We use `source` as we want to export variables
source ./utils/helper-prepare-wallets.sh
````

## Deploy artifacts

````bash
# TODO
## A simple script to perform the deployments and export the env variables

# For now, we will just execute the commands
# Skip these step and fill out the variables if you already have
# the artifacts deployed.

forge script script/DeploySafe.s.sol --rpc-url $RPC_URL --broadcast

# See the script output
export SAFE_ADDRESS="<SAFE_ADDRESS>"

forge create src/SimpleContract.sol:SimpleContract \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY_0 \
    --broadcast \
    --constructor-args "$SAFE_ADDRESS"

# See the script output
export SIMPLE_CONTRACT_ADDRESS="<SIMPLE_CONTRACT_ADDRESS>"
````

## Check the Deployed Artifacts

````bash
./utils/check-deployed-artifacts.sh
````

## Multisig Operations

### Proposal

To create a proposal, we need the **nonce**. Only after the first confirmation we will able to see the status of the proposal.

````bash
# This script will set up the following env variables
## PROPOSAL_NONCE
## SAFE_TX_HASH

source ./utils/helper-create-proposal.sh
````

### Confirmations

````bash
# Add the desired key index as a parameter
source ./utils/helper-create-confirmation.sh 1

source ./utils/helper-create-confirmation.sh 2

source ./utils/helper-create-confirmation.sh 5
````

````bash
# Check the status of the proposal

 ./utils/check-safe-status.sh
````

### Execution

````bash
./utils/helper-execute-transaction.sh
````

````bash
./utils/check-simple-contract-value.sh
````

## Summary

````bash
## Preparation and Deployment
source ./utils/helper-prepare-wallets.sh
forge script script/DeploySafe.s.sol --rpc-url $RPC_URL --broadcast
export SAFE_ADDRESS="<SAFE_ADDRESS>" # (See the script output)
forge create src/SimpleContract.sol:SimpleContract \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY_0 \
    --broadcast \
    --constructor-args "$SAFE_ADDRESS"
export SIMPLE_CONTRACT_ADDRESS="<SIMPLE_CONTRACT_ADDRESS>" ### (See the script output)

## Proposal / Confirmations / Execution
source ./utils/helper-create-proposal.sh
source ./utils/helper-create-confirmation.sh 5
source ./utils/helper-create-confirmation.sh 1
source ./utils/helper-create-confirmation.sh 2
./utils/helper-execute-transaction.sh

## Checks
./utils/check-deployed-artifacts.sh
./utils/check-safe-status.sh
./utils/check-simple-contract-value.sh
````
