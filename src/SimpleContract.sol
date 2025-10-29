// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleContract is Ownable {
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
