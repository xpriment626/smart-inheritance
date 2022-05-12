// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

error UnAuthorised();
error ReentrantCall();
error TooEarly();
error InsufficientBalance();

/**
* @title Inherit
* @author Emmett
* @dev This contract allows the owner to assign an heir
*      who is then able to inherit the contract and all 
*      Ether stored if the owner fails to refresh
*      the inheritance timer within one month.
*/
contract Inherit {

    /// @dev one month in seconds
    uint256 public constant ONE_MONTH = 2629800;
    address payable public owner;
    address payable public heir;
    uint256 public lastWithdrawal;

    /// @dev constant state variables for locked and unlocked
    ///      are stored into one 256-bit slot in order to implement
    ///      gas efficient reentrancy protection.
    uint128 private constant isLocked = 1;
    uint128 private constant isUnlocked = 2;
    uint256 public status; 

    /// @dev owner and heir are explicitly declared in constructor
    constructor(address payable _owner, address payable _heir) {
        owner = _owner;
        heir = _heir;
        status = isLocked;
        lastWithdrawal = block.timestamp;
    }
    receive() external payable {}

    modifier onlyHeir {
        if (msg.sender != heir) revert UnAuthorised();
        _;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert UnAuthorised();
        _;
    }

    modifier noReentry {
        if (status == isUnlocked) revert ReentrantCall();
        status = isUnlocked;
        _;
        status = isLocked;
    }
    
    /// @param _amount to withdraw
    function withdraw(uint256 _amount) external payable onlyOwner noReentry {
        uint256 balance = address(this).balance;
        if(_amount > balance) revert InsufficientBalance();
        lastWithdrawal = block.timestamp;
        owner.transfer(_amount);
    }
    
    ///@param _newHeir must be passed in by the current heir
    function inherit(address payable _newHeir) external onlyHeir {
        if(block.timestamp < lastWithdrawal + ONE_MONTH) revert TooEarly();
        owner = heir;
        heir = _newHeir;
        lastWithdrawal = block.timestamp;
    }
}
