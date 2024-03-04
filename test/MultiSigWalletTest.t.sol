// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;
import {Test, console} from "forge-std/Test.sol";

import {MultiSigWallet, SimpleStorage} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet multiSigWallet;
    SimpleStorage simpleStorage;
    address[] public owners;

    function setUp() public {
        owners.push(makeAddr("owner1"));
        owners.push(makeAddr("owner2"));
        multiSigWallet = new MultiSigWallet(owners, 2);
        simpleStorage = new SimpleStorage(address(multiSigWallet));
        deal(owners[0], 100 ether);
        deal(owners[1], 100 ether);
    }

    function testOwners() public {
        console.log("owners: ", multiSigWallet.s_owners(0));
        console.log("owners: ", multiSigWallet.s_owners(1));
        assertTrue(multiSigWallet.s_owners(0) == owners[0]);
        assertTrue(multiSigWallet.s_owners(1) == owners[1]);
    }

    function testStorageOwner() public {
        console.log("storage owner: ", simpleStorage.s_owner());
        assertTrue(simpleStorage.s_owner() == address(multiSigWallet));
    }

    function testTransactionSubmit() public {
        console.log("storage value: ", simpleStorage.s_storage());
        vm.prank(owners[0]);
        multiSigWallet.submitTransaction(
            address(simpleStorage),
            0,
            abi.encodeWithSignature("store(uint256)", 100)
        );
        vm.prank(owners[0]);
        multiSigWallet.confirmTransaction(0);
        vm.startPrank(owners[1]);
        multiSigWallet.confirmTransaction(0);
        multiSigWallet.executeTransaction(0);
        vm.stopPrank();
        assertTrue(simpleStorage.s_storage() == 100);
        console.log("storage value: ", simpleStorage.s_storage());
    }
}
