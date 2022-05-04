// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

error UnAuthorised();
error ReentrantCall();
error DOSAttempt();
error InvalidHeir();
error FatalSetup();

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
    uint256 public balance;
    uint256 public lastWithdrawal;

    /// @dev immutable state variables for locked and unlocked
    ///      are stored into one 256-bit slot in order to implement
    ///      gas efficient reentrancy protection.
    uint128 private immutable isLocked = 1;
    uint128 private immutable isUnlocked = 2;
    uint256 public status;

    /// @dev owner and heir are explicitly declared in constructor
    constructor(address _owner, address _heir) {
        if (_owner == address(0) || _heir == address(0)) revert FatalSetup();
        if (_owner == _heir) revert InvalidHeir();
        owner = payable(_owner);
        heir = payable(_heir);
        status = isLocked;
    }

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

    /// @dev empty deposits are not allowed
    function deposit() external payable {
        if (msg.value == 0) revert DOSAttempt();
        balance += msg.value;
    }

    /**
    * @param _amount to withdraw
    * @dev refreshes last deposit time if 
    *      withdrawal amount is 0 and caller is owner. 
    */
    function withdraw(uint256 _amount) external payable onlyOwner {
        if (_amount == 0) {
            lastWithdrawal = block.timestamp;
        }
        uint256 _balance = balance;
        require(_amount <= _balance, "ERROR: Insufficient funds");
        lastWithdrawal = block.timestamp;
        balance -= _amount;
        owner.transfer(_amount);
    }

    /**
    * @param _newHeir must be passed in by the current heir
    *                 before inheriting the contract.
    * @dev the new heir address cannot be 0x0, previous owner, or self
    */
    function inherit(address _newHeir) external onlyHeir {
        if (_newHeir == address(0) 
            || _newHeir == msg.sender 
            || _newHeir == owner) revert InvalidHeir();
        uint256 _lastWithdrawal = lastWithdrawal;
        require(block.timestamp > _lastWithdrawal + ONE_MONTH, "ERROR: Too early");
        owner = payable(msg.sender);
        heir = payable(_newHeir);
    }
}
