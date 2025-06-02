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


#### Solutions 

Command : `echidna crytic/challenge01Fuzztesting.sol --contract AllInvariants --config config.yaml;`