// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
import "../lib/forge-std/src/Test.sol";

import {EthPool} from "src/EthPool.sol";

import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";

contract ContractTest is Test {
    using SafeTransferLib for address;

    EthPool public ethPool;
    address userA = address(0xA);
    address userB = address(0xB);

    function setUp() public {
        ethPool = new EthPool();
        userA.safeTransferETH(1000 ether);
        userB.safeTransferETH(1000 ether);
    }

    function testFund() public {
        assertTrue(ethPool.ethBalance() == 0);

        ethPool.fund{value: 1 ether}();

        assertTrue(ethPool.ethBalance() == 1 ether);
    }

    function testFund2() public {
        ethPool.fund{value: 1 ether}();
        ethPool.fund{value: 2 ether}();

        assertTrue(ethPool.ethBalance() == 3 ether);
    }

    function testDeposit1() public {
        vm.prank(userA);
        ethPool.deposit{value: 100 ether}();

        uint256 userAShares;
        assertEq(userAShares = ethPool.balanceOf(userA), 100 ether);
        assertEq(ethPool.ethBalance(), 100 ether);

        uint256 userABalanceBefore = userA.balance;
        vm.prank(userA);
        ethPool.withdraw(userAShares);

        assertEq(ethPool.balanceOf(userA), 0);
        assertEq(ethPool.ethBalance(), 0);
        assertEq(userA.balance - userABalanceBefore, 100 ether);
    }

    function testDeposit2() public {
        vm.prank(userA);
        ethPool.deposit{value: 100 ether}();

        vm.prank(userB);
        ethPool.deposit{value: 300 ether}();

        uint256 userAShares;
        uint256 userBShares;
        assertEq(userAShares = ethPool.balanceOf(userA), 100 ether);
        assertEq(userBShares = ethPool.balanceOf(userB), 300 ether);
        assertEq(ethPool.ethBalance(), 400 ether);

        uint256 userABalanceBefore = userA.balance;
        vm.prank(userA);
        ethPool.withdraw(userAShares);

        uint256 userBBalanceBefore = userB.balance;
        vm.prank(userB);
        ethPool.withdraw(userBShares);

        assertEq(ethPool.balanceOf(userA), 0);
        assertEq(ethPool.balanceOf(userB), 0);
        assertEq(ethPool.ethBalance(), 0);
        assertEq(userA.balance - userABalanceBefore, 100 ether);
        assertEq(userB.balance - userBBalanceBefore, 300 ether);
    }

    function testScenario() public {
        vm.prank(userA);
        ethPool.deposit{value: 100 ether}();

        vm.prank(userB);
        ethPool.deposit{value: 300 ether}();

        // fund of 200 ether should be split as 50 ether to userA and 150 ether to userB
        // gotcha: here msg.sender is this contract and not userB
        ethPool.fund{value: 200 ether}();

        uint256 userABalanceBefore = userA.balance;
        uint256 userAShares = ethPool.balanceOf(userA);
        vm.prank(userA);
        ethPool.withdraw(userAShares);

        uint256 userBBalanceBefore = userB.balance;
        uint256 userBShares = ethPool.balanceOf(userB);
        vm.prank(userB);
        ethPool.withdraw(userBShares);

        assertEq(userA.balance - userABalanceBefore, 100 ether + 50 ether);
        assertEq(userB.balance - userBBalanceBefore, 300 ether + 150 ether);
    }
}
