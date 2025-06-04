# ERC-20 Spot the Bug

Buggy ERC-20 is a collection of 20 ERC-20 implementations with a bug injected in them.

These are serious bugs that could lead to catastrophic behavior, or significantly deviate from what the developer intended the behavior to be. Each implementation has a serious bug. While it is helpful to familiarize yourself with [weird ERC-20 tokens](https://github.com/d-xo/weird-erc20), the bugs we inserted here are much more problematic than the deviations described in the weird ERC-20 tokens repository.

It should be obvious, but **Do not use this code for production, it is for educational purposes.**

Here is how you can look for bugs:
- Is code or logic missing that should be there?
- Does each ERC-20 function actually function according to the standard? 
- For any functions or functionalities that are added on to the standard, do they behave as expected?
- Are there any typos that allow the code to compile and run, but cause a deviation from expected behavior?

We recommend reading the [ERC-20 standard](https://eips.ethereum.org/EIPS/eip-20) first very closely, and perhaps even implementing an ERC-20 token from scratch first so you have a clear idea of how an ERC-20 token ought to behave.

Unlike other CTFs, we do not provide unit tests to confirm your findings, as those could be used as unrealistic hints for where to find the bug.

If you get stuck, ask a state-of-the-art LLM for the answer, or to give you a hint. In our testing, modern LLMs with thinking capabilities (i.e. they process the answer for some time before giving it) can find the bugs reliably.

## Credits
We used the Solmate and OpenZeppelin ERC-20 implementations as starting points.

## License
This work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

Please see the full license [here](https://creativecommons.org/licenses/by-nc-sa/4.0/).

## Authors
This work was created by [BlockChomper](https://x.com/DegenShaker).


### This was done as a challenge to learn fuzzful testing

## Identified Issues and Testing

### Prerequisites
- [Echidna](https://github.com/crytic/echidna) - Property-based fuzzing tool
- [Foundry](https://github.com/foundry-rs/foundry) - Ethereum development toolkit

### How to Test
Each challenge can be tested using Echidna fuzzing with the provided test contracts:

```bash
echidna crytic/Challenge[XX]FuzzTesting.sol --config config.yaml
```

Replace `[XX]` with the challenge number (01-20).

### Solutions - Bugs Found with Echidna Fuzzing

1. **Challenge01: Missing Balance Deduction in Transfer**
   - **Issue**: Transfer function doesn't subtract balance from sender
   - **Impact**: Tokens can be created out of thin air during transfers
   - **Test**: `echidna crytic/Challenge01FuzzTesting.sol --config config.yaml`

2. **Challenge02: Missing Access Control on Approve**
   - **Issue**: Missing access control and zero address checks on approve function
   - **Impact**: Anyone can set allowances for any address
   - **Test**: `echidna crytic/Challenge02FuzzTesting.sol --config config.yaml`

3. **Challenge03: Missing Access Control on Burn**
   - **Issue**: Anyone can burn anyone's tokens without permission
   - **Impact**: Malicious users can destroy other users' tokens
   - **Test**: `echidna crytic/Challenge03FuzzTesting.sol --config config.yaml`

4. **Challenge04: Missing Pause Check in TransferFrom**
   - **Issue**: transferFrom function missing pause modifier while other functions have it
   - **Impact**: Transfers can continue even when contract is paused
   - **Test**: `echidna crytic/Challenge04FuzzTesting.sol --config config.yaml`

5. **Challenge05: Swapped From/To Parameters**
   - **Issue**: Transfer function parameters 'from' and 'to' are interchanged in logic
   - **Impact**: Transfers go to wrong addresses
   - **Test**: `echidna crytic/Challenge05FuzzTesting.sol --config config.yaml`

6. **Challenge06: Missing Blacklist Check for From Address**
   - **Issue**: Blacklist check only applied to 'to' address, not 'from' address
   - **Impact**: Blacklisted addresses can still send tokens
   - **Test**: `echidna crytic/Challenge06FuzzTesting.sol --config config.yaml`

7. **Challenge07: Missing Access Control on Mint**
   - **Issue**: Anyone can mint tokens, missing onlyOwner modifier
   - **Impact**: Unlimited token inflation by any user
   - **Test**: `echidna crytic/Challenge07FuzzTesting.sol --config config.yaml`

8. **Challenge08: Missing Total Supply Update on Burn**
   - **Issue**: Burn function doesn't decrease total supply
   - **Impact**: Total supply becomes inaccurate, affecting token economics
   - **Test**: `echidna crytic/Challenge08FuzzTesting.sol --config config.yaml`

9. **Challenge09: Missing Overflow Protection**
   - **Issue**: Transfer function uses unchecked block without proper balance validation
   - **Impact**: Potential integer underflow leading to balance manipulation
   - **Test**: `echidna crytic/Challenge09FuzzTesting.sol --config config.yaml`

10. **Challenge10: Broken Owner Modifier**
    - **Issue**: onlyOwner modifier uses assignment (==) instead of require statement
    - **Impact**: Access control completely bypassed, anyone can call owner functions
    - **Test**: `echidna crytic/Challenge10FuzzTesting.sol --config config.yaml`

11. **Challenge11: Wrong Allowance Decrement**
    - **Issue**: transferFrom decrements wrong allowance mapping and missing infinite allowance handling
    - **Impact**: Allowances tracked incorrectly, infinite approvals broken
    - **Test**: `echidna crytic/Challenge11FuzzTesting.sol --config config.yaml`

12. **Challenge12: Missing Total Supply Increase on Gift**
    - **Issue**: Gift function (mint) doesn't increase total supply
    - **Impact**: Total supply becomes inaccurate, tokens created without proper accounting
    - **Test**: `echidna crytic/Challenge12FuzzTesting.sol --config config.yaml`

13. **Challenge13: Wrong Allowance Mapping in Approve**
    - **Issue**: Approve function sets allowance[spender][owner] instead of allowance[owner][spender]
    - **Impact**: Allowances set in wrong direction, transfers will fail
    - **Test**: `echidna crytic/Challenge13FuzzTesting.sol --config config.yaml`

14. **Challenge14: Wrong Infinite Allowance Logic**
    - **Issue**: Infinite allowance check uses == instead of !=, decrements infinite allowances
    - **Impact**: Infinite allowances get consumed, breaking intended behavior
    - **Test**: `echidna crytic/Challenge14FuzzTesting.sol --config config.yaml`

15. **Challenge15: Missing Balance Increase in Mint**
    - **Issue**: _mint function increases total supply but doesn't increase recipient's balance
    - **Impact**: Tokens minted but not credited to recipient
    - **Test**: `echidna crytic/Challenge15FuzzTesting.sol --config config.yaml`

16. **Challenge16: Missing Allowance Setting in Approve**
    - **Issue**: Approve function emits event but doesn't actually set the allowance
    - **Impact**: Approvals appear successful but don't work
    - **Test**: `echidna crytic/Challenge16FuzzTesting.sol --config config.yaml`

17. **Challenge17: Wrong Balance Validation in Transfer**
    - **Issue**: Transfer validates recipient's balance instead of sender's balance
    - **Impact**: Transfers can fail incorrectly or succeed when they shouldn't
    - **Test**: `echidna crytic/Challenge17FuzzTesting.sol --config config.yaml`

18. **Challenge18: Missing Total Supply Update in Mint**
    - **Issue**: _mint function increases balance but doesn't increase total supply
    - **Impact**: Total supply becomes inaccurate, breaking token economics
    - **Test**: `echidna crytic/Challenge18FuzzTesting.sol --config config.yaml`

19. **Challenge19: Missing Balance Deduction in Transfer**
    - **Issue**: Transfer function doesn't subtract from sender's balance
    - **Impact**: Infinite tokens can be transferred without deducting from sender
    - **Test**: `echidna crytic/Challenge19FuzzTesting.sol --config config.yaml`

20. **Challenge20: Wrong Allowance Update in TransferFrom**
    - **Issue**: transferFrom increases allowance instead of decreasing it
    - **Impact**: Allowances grow instead of being consumed, breaking spending limits
    - **Test**: `echidna crytic/Challenge20FuzzTesting.sol --config config.yaml`

### Testing All Challenges
To test all challenges at once, you can use:

```bash
for i in {01..20}; do
    echo "Testing Challenge$i..."
    echidna crytic/Challenge${i}FuzzTesting.sol --config config.yaml
    echo "---"
done
``` 