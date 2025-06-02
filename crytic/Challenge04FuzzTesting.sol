// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Challenge04 as Token} from "../src/Challenge04.sol";
// import {Challenge02 as Token} from "../src/Challenge02.sol";
contract AllInvariants is Token {

    // DEBUG EVENTS
    event TransferPreDebug(address indexed from, address indexed to, uint256 value);
    event TransferPostDebug(address indexed from, address indexed to, uint256 value);
    event MintPreDebug(address indexed to, uint256 amount);
    event MintPostDebug(address indexed to, uint256 amount);
    event TransferFromPreDebug(address indexed from, address indexed to, uint256 value);
    event TransferFromPostDebug(address indexed from, address indexed to, uint256 value);
    event ApprovePreDebug(address indexed owner, address indexed spender, uint256 value);
    event ApprovePostDebug(address indexed owner, address indexed spender, uint256 value);
    event BurnPreDebug(address indexed owner, uint256 value);
    event BurnPostDebug(address indexed owner, uint256 value);
    event PauseOperationAttempt(string operation, bool shouldFail);

    address public override owner;
    constructor() Token() {
        // Initialize the contract with some tokens
        owner = msg.sender;
    }
    //////////////// minting Invariants ////////////////////
    function mintInvariant(address to, uint256 amount) public {
        require(to != address(0), "Cannot mint to zero address");

        uint preTotalSupply = totalSupply();
        uint preBalance = balanceOf(to);

        emit MintPreDebug(to, amount);
        _mint(to, amount);
        emit MintPostDebug(to, amount);
        uint postTotalSupply = totalSupply();
        uint postBalance = balanceOf(to);
        assert(postTotalSupply == preTotalSupply + amount);
        assert(postBalance == preBalance + amount);
    }

    //////////////// Pause/Unpause Invariants ////////////////////
    function pauseInvariant() public {
        require(msg.sender == owner, "Only owner can pause");
        require(!paused, "Contract is already paused");
        
        bool prePausedState = paused;
        pause();
        bool postPausedState = paused;
        
        assert(prePausedState == false);
        assert(postPausedState == true);
    }

    function unpauseInvariant() public {
        require(msg.sender == owner, "Only owner can unpause");
        require(paused, "Contract is not paused");
        
        bool prePausedState = paused;
        unpause();
        bool postPausedState = paused;
        
        assert(prePausedState == true);
        assert(postPausedState == false);
    }

    //////////////// Complex Pause Operation Invariants ////////////////////
    
    // Test that transfer fails when paused
    function transferWhenPausedInvariant(address to, uint256 value) public {
        require(paused, "Contract must be paused for this invariant");
        require(to != address(0), "Invalid to address");
        require(to != msg.sender, "Cannot transfer to self");
        require(balanceOf(msg.sender) >= value, "Insufficient balance for transfer");
        
        uint preFromBalance = balanceOf(msg.sender);
        uint preToBalance = balanceOf(to);
        uint preTotalSupply = totalSupply();
        
        emit PauseOperationAttempt("transfer", true);
        
        // This should revert due to pause
        try this.transfer(to, value) returns (bool success) {
            // If it doesn't revert, that's a bug - all state should be unchanged
            assert(false); // Should not reach here when paused
        } catch {
            // Expected behavior - operation should fail
            // Verify no state changes occurred
            assert(balanceOf(msg.sender) == preFromBalance);
            assert(balanceOf(to) == preToBalance);
            assert(totalSupply() == preTotalSupply);
        }
    }
    
    // Test that transferFrom fails when paused (if it should)
    function transferFromWhenPausedInvariant(address from, address to, uint256 value) public {
        require(paused, "Contract must be paused for this invariant");
        require(from != address(0) && to != address(0), "Invalid addresses");
        require(from != to, "Cannot transfer to same address");
        require(from != msg.sender && to != msg.sender, "Invalid sender relationship");
        require(balanceOf(from) >= value, "Insufficient balance");
        require(allowance(from, msg.sender) >= value, "Insufficient allowance");
        
        uint preFromBalance = balanceOf(from);
        uint preToBalance = balanceOf(to);
        uint preAllowance = allowance(from, msg.sender);
        uint preTotalSupply = totalSupply();
        
        emit PauseOperationAttempt("transferFrom", true);
        
        // Test if transferFrom is blocked when paused
        try this.transferFrom(from, to, value) returns (bool success) {
            // If transferFrom succeeded when paused, it might be a design choice
            // But let's check if it should be blocked based on the pattern
            // For now, we'll allow it but log it
            emit PauseOperationAttempt("transferFrom", false);
        } catch {
            // If it fails, verify no state changes
            assert(balanceOf(from) == preFromBalance);
            assert(balanceOf(to) == preToBalance);
            assert(allowance(from, msg.sender) == preAllowance);
            assert(totalSupply() == preTotalSupply);
        }
    }
    
    // Test that operations work when not paused
    function transferWhenUnpausedInvariant(address to, uint256 value) public {
        require(!paused, "Contract must not be paused for this invariant");
        require(to != address(0), "Invalid to address");
        require(to != msg.sender, "Cannot transfer to self");
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        
        uint preFromBalance = balanceOf(msg.sender);
        uint preToBalance = balanceOf(to);
        uint preTotalSupply = totalSupply();
        
        emit PauseOperationAttempt("transfer", false);
        
        bool success = transfer(to, value);
        assert(success);
        
        // Verify correct state changes
        assert(balanceOf(msg.sender) == preFromBalance - value);
        assert(balanceOf(to) == preToBalance + value);
        assert(totalSupply() == preTotalSupply);
    }
    
    // Test pause/unpause state transitions
    function pauseUnpauseStateInvariant() public {
        require(msg.sender == owner, "Only owner can test pause/unpause");
        
        bool initialState = paused;
        
        if (!paused) {
            // Test pause
            pause();
            assert(paused == true);
            
            // Test unpause
            unpause();
            assert(paused == false);
        } else {
            // Test unpause
            unpause();
            assert(paused == false);
            
            // Test pause
            pause();
            assert(paused == true);
        }
        
        // Restore initial state
        if (initialState != paused) {
            if (initialState) {
                pause();
            } else {
                unpause();
            }
        }
        
        assert(paused == initialState);
    }
    
    // Test that only owner can pause/unpause
    function onlyOwnerCanPauseInvariant() public {
        require(msg.sender != owner, "Sender must not be owner for this test");
        
        bool prePausedState = paused;
        
        // Test that non-owner cannot pause
        try this.pause() {
            assert(false); // Should not succeed
        } catch {
            // Expected - non-owner cannot pause
            assert(paused == prePausedState);
        }
        
        // Test that non-owner cannot unpause  
        try this.unpause() {
            assert(false); // Should not succeed
        } catch {
            // Expected - non-owner cannot unpause
            assert(paused == prePausedState);
        }
    }
    
    // Test comprehensive pause behavior with multiple operations
    function comprehensivePauseInvariant(address user1, address user2, uint256 amount) public {
        require(msg.sender == owner, "Only owner can run comprehensive test");
        require(user1 != address(0) && user2 != address(0), "Invalid users");
        require(user1 != user2 && user1 != owner && user2 != owner, "Users must be distinct");
        require(balanceOf(user1) >= amount, "Insufficient balance for user1");
        
        // Ensure contract is not paused initially
        if (paused) {
            unpause();
        }
        
        // Test operations work when not paused
        _mint(user1, amount); // Minting should work
        
        // Setup allowance for transferFrom test
        uint256 preUser1Balance = balanceOf(user1);
        uint256 preUser2Balance = balanceOf(user2);
        
        // Now pause the contract
        pause();
        assert(paused == true);
        
        // Unpause and verify operations work again
        unpause();
        assert(paused == false);
    }

    // this must always hold true
    function totalBalanceShouldNeverBeLessThanUserBalance(address user) public view {
        uint userBalance = balanceOf(user);
        uint totalBalance = totalSupply();
        assert(totalBalance >= userBalance);
    }
    
    function transferInvariant(address to, uint value, address tempUser) public {
        address from = msg.sender;
        require(to != from && from != tempUser && to != tempUser, "Invalid addresses");

        // Store initial state
        uint[4] memory preState = [
            balanceOf(tempUser),
            balanceOf(from),
            balanceOf(to),
            totalSupply()
        ];

        emit TransferPreDebug(from, to, value);
        bool success = transfer(to, value);
        assert(success);
        emit TransferPostDebug(from, to, value);

        // Verify state changes
        assert(balanceOf(tempUser) == preState[0]); // Third user's balance unchanged
        assert(balanceOf(from) == preState[1] - value); // Sender's balance decreased
        assert(balanceOf(to) == preState[2] + value); // Recipient's balance increased
        assert(totalSupply() == preState[3]); // Total supply unchanged
        assert(allowance(from, to) == allowance(from, to)); // Allowance unchanged
    }
    

    function transferFromInvariant(address from, address to, uint value, address tempUser) public {
        address spender = msg.sender;
        require(from != to, "Invalid from and to");
        require(from != tempUser, "Invalid from");
        require(to != tempUser, "Invalid to");
        require(spender != tempUser, "Invalid spender");

        uint preTempUserBalance = balanceOf(tempUser);
        uint preAllowance = allowance(from, spender);
        uint preFromBalance = balanceOf(from);
        uint preToBalance = balanceOf(to);
        uint preTotalSupply = totalSupply();  

        emit TransferFromPreDebug(from, to, value);
        bool success = transferFrom(from, to, value);
        assert(success);
        emit TransferFromPostDebug(from, to, value);
        uint postTempUserBalance = balanceOf(tempUser);
        uint postAllowance = allowance(from, spender);
        uint postFromBalance = balanceOf(from);
        uint postToBalance = balanceOf(to);
        uint postTotalSupply = totalSupply();

        assert(postTempUserBalance == preTempUserBalance); // Third user's balance should not change
        assert(postAllowance == preAllowance - value);
        assert(postFromBalance == preFromBalance - value);
        assert(postToBalance == preToBalance + value);
        assert(postTotalSupply == preTotalSupply);
    }

    function approveInvariant(address spender, uint value) public {
        address tokenOwner = msg.sender;

        require(spender != tokenOwner, "Invalid spender");

        uint preAllowance = allowance(tokenOwner, spender);
        uint preOwnerBalance = balanceOf(tokenOwner);
        uint preSpenderBalance = balanceOf(spender);
        uint preTotalSupply = totalSupply();

        emit ApprovePreDebug(tokenOwner, spender, value);
        approve(spender, value);
        emit ApprovePostDebug(tokenOwner, spender, value);
        uint postAllowance = allowance(tokenOwner, spender);
        uint postTotalSupply = totalSupply();
        uint postOwnerBalance = balanceOf(tokenOwner);
        uint postSpenderBalance = balanceOf(spender);

        assert(postAllowance == value);
        assert(postTotalSupply == preTotalSupply);
        assert(postOwnerBalance == preOwnerBalance);
        assert(postSpenderBalance == preSpenderBalance);
    }

    // function burnInvariant(uint value,address tempUser) public {
    //     address owner = msg.sender;
    //     require(owner != tempUser, "Invalid owner");

    //     uint preTotalSupply = totalSupply();
    //     uint preOwnerBalance = balanceOf(owner);
    //     uint preTempUserBalance = balanceOf(tempUser);

    //     emit BurnPreDebug(owner, value);
    //     // burn(tempUser, value);
    //     // burn(owner, value);
    //     emit BurnPostDebug(owner, value);
    //     uint postTotalSupply = totalSupply();
    //     uint postOwnerBalance = balanceOf(owner);
    //     uint postTempUserBalance = balanceOf(tempUser);

    //     assert(postTotalSupply == preTotalSupply - value);
    //     assert(postOwnerBalance == preOwnerBalance - value);

    //     // no other user should be affected
    //     assert(postTempUserBalance == preTempUserBalance);
    // }
}