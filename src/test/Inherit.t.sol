// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import { VmExtended } from "../../lib/vm-extended/src/VmExtended.sol";
import { Inherit } from "../Inherit.sol";

error DOSAttempt();
error UnAuthorised();
error FatalSetup();
error InvalidHeir();
contract ContractTest is VmExtended {

    event Log(string);

    address public annie;
    address public bob;
    address public badGuy;
    address public charlie;
    uint256 public constant ONE_MONTH = 2629800;

    Inherit instance;
    function setUp() public {
        (annie, bob, badGuy) = initAccounts(1, 2, 3);
        charlie = initWithETH(4);
        instance = new Inherit(annie, bob);
        emit Log("Accounts and contract instance initialised!");
    }

    function testSetup() public {
        emit Log("Sanity check for default state variables");
        Inherit tester = new Inherit(annie, bob);
        address owner = tester.owner();
        address heir = tester.heir();
        uint256 lastWithdrawal = tester.lastWithdrawal();
        uint256 status = tester.status();

        assertEq(lastWithdrawal, 0);
        assertEq(status, 1);
        assertEq(owner, annie);
        assertEq(heir, bob);
    }

    function testFatalSetup() public {
        emit Log("It should NOT allow address(0) for any construcot args");
        vm_extended.expectRevert(FatalSetup.selector);
        new Inherit(address(0), address(0));
    }

    function testMaliciousSetup() public {
        emit Log("It should NOT allow same heir and owner as constructor args");
        address user = initWithETH(109);
        vm_extended.expectRevert(InvalidHeir.selector);
        new Inherit(user, user);
    }

    function testWithdrawal() public {
        emit Log("It should allow withdrawals");
        vm_extended.startPrank(annie);
        instance.deposit{value: 10 ether}();
        instance.withdraw(10 ether);
        vm_extended.stopPrank();
        
        uint256 balance = instance.balance();
        assertEq(balance, 0);
    }

    function testUnknownWithdrawal(uint64 amount) public {
        emit Log("Fuzz test should revert for any amount if caller is not the owner");
        vm_extended.expectRevert(UnAuthorised.selector);
        vm_extended.prank(badGuy);
        instance.withdraw(amount);
    }

    function testFailBogusWithdrawals() public {
        emit Log("It should NOT permit withdrawals above current ETH balance");
        address owner = instance.owner();
        vm_extended.prank(owner);
        instance.withdraw(9999);
    }

    function testDeposit() public {
        emit Log("It should allow deposits");
        address owner = instance.owner();
        vm_extended.prank(owner);
        instance.deposit{value: 50 ether}();
        uint256 balance = instance.balance();

        assertEq(balance, 50 ether);
    }

    function testDOSAttempt() public {
        emit Log("It should NOT allow empty transactions");
        vm_extended.expectRevert(DOSAttempt.selector);
        vm_extended.prank(badGuy);
        instance.deposit{value: 0 ether}();
        vm_extended.warp(block.timestamp + 1);
        vm_extended.expectRevert(DOSAttempt.selector);
        vm_extended.prank(badGuy);
        instance.deposit{value: 0 ether}();
    }

    function testInherit() public {
        emit Log("Sanity check for time passage");
        uint256 jump = 15 days;
        uint256 start = instance.lastWithdrawal();
        vm_extended.warp(block.timestamp + jump);
        assertEq(block.timestamp, start + jump);

        vm_extended.prank(annie);
        instance.withdraw(0);
        vm_extended.warp(block.timestamp + ONE_MONTH + 5 minutes);
        vm_extended.prank(bob);
        instance.inherit(charlie);

        emit Log("It should update owner and heir values once existing heir inherits");
        address newOwner = instance.owner();
        address newHeir = instance.heir();

        assertEq(newOwner, bob);
        assertEq(newHeir, charlie);
    }

    function testMalicousInherit() public {
        emit Log("New heir should NOT be address(0)");
        emit Log("New heir should NOT be current heir");
        emit Log("New heir should NOT be previous owner");
        
        vm_extended.prank(annie);
        instance.withdraw(0);
        vm_extended.warp(block.timestamp + ONE_MONTH + 5 minutes);

        vm_extended.startPrank(bob);
        vm_extended.expectRevert(InvalidHeir.selector);
        instance.inherit(annie);
        vm_extended.expectRevert(InvalidHeir.selector);
        instance.inherit(bob);
        vm_extended.expectRevert(InvalidHeir.selector);
        instance.inherit(address(0));
        vm_extended.stopPrank();
    }

    function testFailEarlyInherit() public {
        emit Log("It should NOT allow inheritance before expiry");
        vm_extended.prank(annie);
        instance.withdraw(0);
        vm_extended.prank(bob);
        instance.inherit(charlie);
    }
}
