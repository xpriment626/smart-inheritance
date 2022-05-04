<h1 align="center">Solidity Programming Challenge: Inheritance Contract</h1>

## Overview

**The specification of this contract are as follows:**

-   Allows owner to withdraw ETH from the contract
-   Deposits can come from any source so long as deposit amount is not 0
-   The owner can assign an heir
-   The heir may inherit the contract if a month goes by without a withdrawal from the owner
-   All withdrawals by owner will refresh the one month timer
-   The owner may enter a withdrawal amount of 0 to refresh the timer

**The contract handles the following fatal error cases:**

-   Does not allow contract to be initialised with the zero address (applies to both owner and heir fields)
-   The owner is not allowed to assign themselves as the heir
-   Deposits of 0 ETH are reverted
-   Withdrawals by non owners are reverted
-   Does not allow inheritance before expiry
-   Does not allow heir to set themselves or previous owner as new heir
-   Does not allow new heir to be set to the zero address
-   Withdraw and inherit functions are explicitly restricted to owner and heir access respectively

## Test Reproduction

### Step 1

Install Foundry

```shell
curl -L https://foundry.paradigm.xyz | bash
```

Then run `foundryup` to install latest version

### Step 3

Clone repo and install dependencies

```shell
git clone git@github.com:xpriment626/smart-inheritance.git
cd smart-inheritance
forge install
```

### Step 3

Run tests with 4 verbosity flags

```shell
forge test -vvvv
```

**Note:** It is important to run the tests with exactly 4 flags to get the most readable version of stack traces. 5 is a bit overkill and any less than 4 does not show emitted Logs.
