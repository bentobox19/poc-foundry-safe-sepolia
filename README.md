# Foundry, Sepolia and Safe Wallets

_Exercises_


<!-- MarkdownTOC -->

- Wallet Preparation
    - Generate a key
    - Send funds from other account
    - Derive 5 wallets and send them funds
- Operate in a local fork of Sepolia
- Deploy Safe Wallet and Simple Contract
    - Deploy a safe wallet
    - Deploy a simple contract for the Safe to interact with
- Interacting with the Multisig and Contract
    - Generate a confirmation

<!-- /MarkdownTOC -->

## Wallet Preparation

### Generate a key

````bash
# Ledger has a derivation path different from cast and MetaMask
## MetaMask & cast: m/44'/60'/0'/0/x
## Ledger Live: m/44'/60'/x'/0/0
export MNEMONIC="..."

# This is your $ADDRESS_0
cast wallet address --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/0"
````

### Send funds from other account

````bash
# Load the mnemonic and/or private key of the funding wallet
export FUNDING_ADDR_MNEMONIC="..."

export PRIVATE_KEY=$(cast wallet private-key --mnemonic "$FUNDING_ADDR_MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/0")

# Load the RPC
export ETH_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/..."

# Send 1 ETH to $ADDRESS_0
# cast will just load $ETH_RPC_URL
cast send $ADDRESS_0 --value 1ether --private-key $PRIVATE_KEY

# Verify the transfer
cast balance $ADDRESS_0
````

### Derive 5 wallets and send them funds

````bash
# You can do a loop -- I prefer to change the derivation key by hand
cast send $(cast wallet address --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/1") --value 0.001ether --private-key $PRIVATE_KEY

# Not so paranoid to do the checks with a loop, though
for i in {0..5}; do
    address=$(cast wallet address --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/$i")
    balance=$(cast balance "$address")
    echo "Address: $address Balance: $balance"
done

# Example
## Address: 0xabc1 Balance: 994999894999055000
## Address: 0xabc2 Balance: 1000000000000000
## Address: 0xabc3 Balance: 1000000000000000
## Address: 0xabc4 Balance: 1000000000000000
## Address: 0xabc5 Balance: 1000000000000000
## Address: 0xabc6 Balance: 1000000000000000
````

## Operate in a local fork of Sepolia

````bash
export ETH_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/..."_Tk_LCg1kGU_20-t0Q-tw

anvil --fork-url $ETH_RPC_URL --port 8545 --chain-id 11155111

# Then you can just unset $ETH_RPC_URL at the terminal that has the MNEMONIC / PRIVATE_KEY
# cast by default will go to localhost:8545
cast balance 0xabc1
1000000000000000
````

IMPORTANT: Make sure that, when you are in this mode, all your other commands to the blockchain point to `localhost:8545`

## Deploy Safe Wallet and Simple Contract

### Deploy a safe wallet

We want to find the addresses in Sepolia for Safe's Singleton and Factory

- Source of Truth: https://github.com/safe-global/safe-deployments
- Docs: https://docs.safe.global/core-api/safe-contracts-deployment
- 1.4.1
  - https://contractscan.xyz/bundle?name=Safe+1.4.1&addresses=0xfd0732dc9e303f09fcef3a7388ad10a83459ec99,0x9b35af71d77eaf8d7e40252370304687390a1a52,0x38869bf66a61cf6bdb996a6ae40d5853fd43b526,0x9641d764fc13c8b624c04430c7356c1c7c8102e2,0x41675c099f32341bf84bfc5382af534df5c7461a,0x29fcb43b46531bca003ddc8fcb67ffe91900c762,0x4e1dcf7ad4e460cfd30791ccc4f9c8a4f820ec67,0xd53cd0ab83d845ac265be939c57f53ad838012c9,0x3d4ba2e0884aa488718476ca2fb8efc291a46199,0x526643F69b81B008F46d95CD5ced5eC0edFFDaC6,0xfF83F6335d8930cBad1c0D439A841f01888D9f69,0xBD89A1CE4DDe368FFAB0eC35506eEcE0b1fFdc54
- Factory
  - https://sepolia.etherscan.io/address/0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67
- Singleton
  https://sepolia.etherscan.io/address/0x41675c099f32341bf84bfc5382af534df5c7461a

Let's write a foundry script to deploy the safe wallet.

````solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Safe} from "@safe-global/safe-contracts/contracts/Safe.sol";
import {SafeProxyFactory} from "@safe-global/safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import {console} from "forge-std/console.sol";

contract DeploySafe is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_WALLET_0");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory owners = new address[](5);
        owners[0] = vm.envAddress("WALLET_1_ADDRESS");
        owners[1] = vm.envAddress("WALLET_2_ADDRESS");
        owners[2] = vm.envAddress("WALLET_3_ADDRESS");
        owners[3] = vm.envAddress("WALLET_4_ADDRESS");
        owners[4] = vm.envAddress("WALLET_5_ADDRESS");

        Safe singleton = Safe(payable(0x41675C099F32341bf84BFc5382aF534df5C7461a));
        SafeProxyFactory factory = SafeProxyFactory(0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67);

        bytes memory initializer = abi.encodeWithSignature("setup(address[],uint256,address,bytes,address,address,uint256,address)",
            owners, 3, address(0), "", address(0), address(0), 0, address(0));

        address safeProxy = address(factory.createProxyWithNonce(address(singleton), initializer, block.timestamp));

        console.log("Safe deployed at:", safeProxy);

        vm.stopBroadcast();
    }
}
````

````bash
# Preparations
export MNEMONIC="..."

export PRIVATE_KEY_WALLET_0=$(cast wallet private-key --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/0")

for i in {1..5}; do
    address=$(cast wallet address --mnemonic "$MNEMONIC" --mnemonic-derivation-path "m/44'/60'/0'/0/$i")
    export WALLET_${i}_ADDRESS="$address"
done

# Run the script
#   --rpc-url option must be included
forge script --rpc-url $ETH_RPC_URL script/DeploySafe.s.sol --broadcast
````

Interact with the safe wallet contract

````bash
# You got the address from the script output
export SAFE_ADDRESS="0xabcabc0.."

cast call $SAFE_ADDRESS "getThreshold()(uint256)"
# 3

cast call $SAFE_ADDRESS "getOwners()(address[])"
# (Array with owners)
````

If you are not in the local fork, you can always look at your contract in Etherscan

- https://sepolia.etherscan.io/address/0x3DE...e99/advanced

### Deploy a simple contract for the Safe to interact with

````solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is Ownable {
    address public safeWallet;

    constructor(address _safeWallet) Ownable(_safeWallet) {
        safeWallet = _safeWallet;
    }

    function storeBlockNumber() external onlyOwner {
        bytes32 slot42 = keccak256(abi.encodePacked(uint256(42)));
        uint256 blockNum = block.number;
        assembly {
            sstore(slot42, blockNum)
        }
    }

    function getStoredBlockNumber() external view returns (uint256) {
        bytes32 slot42 = keccak256(abi.encodePacked(uint256(42)));
        uint256 value;
        assembly {
            value := sload(slot42)
        }
        return value;
    }
}
````

````bash
# Recall that $SAFE_ADDRESS is in the output of the latter deployment
export SAFE_ADDRESS="0xabcabc0.."

# Run the script
## NOTE: Order in the command line options is really important, the following won't work
### forge create src/SimpleContract.sol:SimpleContract --constructor-args "$SAFE_ADDRESS" --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY_WALLET_0
forge create src/SimpleContract.sol:SimpleContract --broadcast --private-key $PRIVATE_KEY_WALLET_0 --constructor-args "$SAFE_ADDRESS" --rpc-url $ETH_RPC_URL

# Do
export SIMPLE_CONTRACT="0xddff..."
````

## Interacting with the Multisig and Contract

We assume that everything has been deployed to Sepolia already.


And that you have an API Key in Safe:

- https://docs.safe.global/core-api/how-to-use-api-keys
- https://developer.safe.global/login

````bash
# Set the key as an env variable here
export SAFE_API_KEY="N2V...1NK"
````

Some documentation in here

- https://docs.safe.global/advanced/smart-account-supported-networks
- https://safe-transaction-sepolia.safe.global/
- https://docs.safe.global/core-api/transaction-service-reference/sepolia

Try it out. Let's get the safes that the user `$WALLET_3_ADDRESS` owns

````bash
# NOTE: If you forget the trailing slash, you will get redirected (301)
curl -X GET https://api.safe.global/tx-service/sep/api/v1/owners/$WALLET_3_ADDRESS/safes/ \
    -H "Accept: application/json" \
    -H "content-type: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY"

# {"safes":["0xabcabc0.."]}%
````

### Generate a confirmation

We want our safe wallet to talk to this deployed `SimpleContract`, particularly to `storeBlockNumber()`

````bash
# STATUS INCOMPLETE
## Learning how to compute `contractTransactionHash``

#######################

# We need the nonce - Take it from the response to this API request
curl -X GET https://api.safe.global/tx-service/sep/api/v1/safes/$SAFE_ADDRESS/ \
    -H "Accept: application/json" \
    -H "content-type: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY"

export PROPOSAL_NONCE=0


# "0x6057361d": Keccak sha3 of `storeBlockNumber()`
# "signatures": Leave empty initially
curl -X POST https://api.safe.global/tx-service/sep/api/v2/safes/$SAFE_ADDRESS/multisig-transactions/ \
    -H "Accept: application/json" \
    -H "content-type: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY" \
    -d '{
  "to": "'$SIMPLE_CONTRACT'",
  "nonce": "'$PROPOSAL_NONCE'",
  "sender": "'$WALLET_1_ADDRESS'",
  "value": "0",
  "data": "0x6057361d",
  "operation": 0,
  "safeTxGas": 0,
  "baseGas": 0,
  "gasPrice": 0,
  "gasToken": "0x0000000000000000000000000000000000000000",
  "refundReceiver": "0x0000000000000000000000000000000000000000",
  "signatures": []
}'
````

We check the proposal we just sent.

````bash
# List a safe's mutisig transactions
curl -X GET https://api.safe.global/tx-service/sep/api/v2/safes/$SAFE_ADDRESS/multisig-transactions/ \
    -H "Accept: application/json" \
    -H "content-type: application/json" \
    -H "Authorization: Bearer $SAFE_API_KEY"
````

