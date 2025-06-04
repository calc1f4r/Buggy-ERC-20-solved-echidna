// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Challenge07 as Token} from "../src/Challenge07.sol";
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

    constructor() Token() {
        // Initialize the contract with some tokens
        owner = msg.sender;
    }
    //////////////// minting Invariants ////////////////////
    function mintInvariant(address to, uint256 amount, address tempUser) public {
        require(to != address(0), "Cannot mint to zero address");

        uint preTotalSupply = totalSupply();
        uint preBalanceTo = balanceOf(to);
        uint preBalanceTempUser = balanceOf(tempUser);
        bool isOwnerMsgSender = msg.sender == owner;
        
        emit MintPreDebug(to, amount);
        
        mint(to, amount);

        if (isOwnerMsgSender) {
            // If the sender is the owner, mint should succeed
            assert(balanceOf(to) == preBalanceTo + amount); // Recipient's balance should increase
            assert(totalSupply() == preTotalSupply + amount); // Total supply should increase
        } else {
            assert(balanceOf(to) == preBalanceTo ); // Balance increases even for non-owner
            assert(totalSupply() == preTotalSupply ); // Total supply increases even for non-owner
        }
        
        // Temp user should not be affected
        assert(balanceOf(tempUser) == preBalanceTempUser);
        emit MintPostDebug(to, amount);
    }


    // this must always hold true
    function totalBalanceShouldNeverBeLessThanUserBalance(address user) public view {
        uint userBalance = balanceOf(user);
        uint totalBalance = totalSupply();
        assert(totalBalance >= userBalance);
    }

    /*
    @
    */
    function transferInvariant(address to, uint value, address tempUser) public {
        address from = msg.sender;
        require(from != tempUser && to != tempUser, "Invalid addresses");
        require(from != to, "Cannot transfer to self"); // Prevent self-transfers
        require(value > 0, "Value must be positive");
        require(balanceOf(from) >= value, "Insufficient balance");
        
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
    }
    

    function transferFromInvariant(address from, address to, uint value, address tempUser) public {
        address spender = msg.sender;
        require(from != tempUser, "Invalid from");
        require(to != tempUser, "Invalid to");
        require(spender != tempUser, "Invalid spender");
        require(from != to, "Cannot transfer to self"); // Prevent self-transfers
        require(value > 0, "Value must be positive");
        require(balanceOf(from) >= value, "Insufficient balance");
        require(allowance(from, spender) >= value, "Insufficient allowance");
        
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
        
        // Handle allowance changes properly - if allowance is max uint256, it shouldn't decrease
        if (preAllowance != type(uint256).max) {
            assert(postAllowance == preAllowance - value);
        } else {
            assert(postAllowance == preAllowance); // Max allowance should remain unchanged
        }
        
        assert(postFromBalance == preFromBalance - value);
        assert(postToBalance == preToBalance + value);
        assert(postTotalSupply == preTotalSupply);
    }

    function approveInvariant(address spender, uint value) public {
        address tokenOwner = msg.sender;

        require(spender != tokenOwner, "Invalid spender");
        require(spender != address(0), "Cannot approve zero address");

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
    // no burn in challenge 5
    // function burnInvariant(uint value,address tempUser) public {
    //     address owner = msg.sender;
    //     require(owner != tempUser, "Invalid owner");

    //     uint preTotalSupply = totalSupply();
    //     uint preOwnerBalance = balanceOf(owner);
    //     uint preTempUserBalance = balanceOf(tempUser);

    //     emit BurnPreDebug(owner, value);
    //     burn(tempUser, value);
    //     burn(owner, value);
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