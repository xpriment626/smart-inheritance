<h1 align="center">Solidity Programming Challenge: Inheritance Contract</h1>

## Overview

**The specification of this contract are as follows:**

-   Allows owner to withdraw ETH from the contract
-   The owner can assign an heir
-   The heir may inherit the contract if a month goes by without a withdrawal from the owner
-   All withdrawals by owner will refresh the one month timer
-   The owner may enter a withdrawal amount of 0 to refresh the timer

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
