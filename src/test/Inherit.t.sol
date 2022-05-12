// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import { VmExtended } from "../../lib/vm-extended/src/VmExtended.sol";
import { Inherit } from "../Inherit.sol";

error UnAuthorised();
error TooEarly();
error InsufficientBalance();
contract ContractTest is VmExtended {

    event Log(string);
    event NumLog(uint256);

    address payable public annie;
    address payable public bob;
    address payable public badGuy;
    address payable public charlie;
    address payable public extra;
    uint256 public constant ONE_MONTH = 2629800;

    Inherit instance;
    function setUp() public {
        (annie, bob, charlie) = initAccounts(1, 2, 3);
        badGuy = initWithETH(4);
        extra = initWithETH(5);
        instance = new Inherit(annie, bob);
        emit Log("Accounts and contract instance initialised!");
    }

    function testOwnerAndHeir() public {
        address owner = instance.owner();
        address heir = instance.heir();
        address expectedOwner = annie;
        address expectedHeir = bob;

        assertEq(owner, expectedOwner);
        assertEq(heir, expectedHeir);
    }

    function testEarlyInherit() public {
        vm_extended.prank(bob);
        vm_extended.expectRevert(TooEarly.selector);
        instance.inherit(charlie);
    }

    function testInherit() public {

        emit Log("First successful inherit");

        uint256 timeIn = instance.lastWithdrawal();
        vm_extended.warp(timeIn + ONE_MONTH + 5 minutes);
        vm_extended.prank(bob);
        instance.inherit(charlie);

        address newOwner = instance.owner();
        address newHeir = instance.heir();

        assertEq(newOwner, bob);
        assertEq(newHeir, charlie);

        emit Log("Failed early inherit");

        vm_extended.prank(charlie);
        vm_extended.expectRevert(TooEarly.selector);
        instance.inherit(badGuy);

        emit Log("Inherit after owner withdrawal + one month");

        vm_extended.prank(bob);
        instance.withdraw(0);
        uint256 updated = instance.lastWithdrawal();
        vm_extended.warp(updated + ONE_MONTH + 5 minutes);
        vm_extended.prank(charlie);
        instance.inherit(extra);

        address thirdOwner = instance.owner();
        address thirdHeir = instance.heir();

        assertEq(thirdOwner, charlie);
        assertEq(thirdHeir, extra);
    }

    function testDepositAndWithdraw() public {
        vm_extended.prank(extra);
        payable(instance).transfer(50 ether);

        uint256 balance = address(instance).balance;
        uint256 expected = 50 ether;

        assertEq(balance, expected);

        vm_extended.prank(annie);
        instance.withdraw(50 ether);

        uint256 balanceAfter = address(instance).balance;
        emit NumLog(balanceAfter);
        assertEq(balanceAfter, 0);
    }

    function testUnAuthorisedCalls() public {
        vm_extended.prank(bob);
        vm_extended.expectRevert(UnAuthorised.selector);
        instance.withdraw(0);

        vm_extended.prank(annie);
        vm_extended.expectRevert(UnAuthorised.selector);
        instance.inherit(extra);
    }

    function testBigWithdrawal() public {
        vm_extended.prank(annie);
        vm_extended.expectRevert(InsufficientBalance.selector);
        instance.withdraw(9999);
    }
}
