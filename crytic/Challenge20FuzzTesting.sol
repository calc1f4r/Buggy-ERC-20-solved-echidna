// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Challenge20 as Token} from "../src/Challenge20.sol";
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

    address public owner;
    constructor() Token("BuggyToken20", "BUG20", 18) {
        // Initialize the contract with some tokens
        owner = msg.sender;
    }
    //////////////// minting Invariants ////////////////////
    function mintInvariant(address to, uint256 amount) public {
        require(to != address(0), "Cannot mint to zero address");

        uint preTotalSupply = totalSupply;
        uint preBalance = balanceOf[to];

        emit MintPreDebug(to, amount);
        _mint(to, amount);
        emit MintPostDebug(to, amount);
        uint postTotalSupply = totalSupply;
        uint postBalance = balanceOf[to];
        assert(postTotalSupply == preTotalSupply + amount);
        assert(postBalance == preBalance + amount);
    }


    // this must always hold true
    function totalBalanceShouldNeverBeLessThanUserBalance(address user) public view {
        uint userBalance = balanceOf[user];
        uint totalBalance = totalSupply;
        assert(totalBalance >= userBalance);
    }

    /*
    @
    */
    function transferInvariant(address to, uint value, address tempUser) public {
        address from = msg.sender;
        require(to != from && from != tempUser && to != tempUser, "Invalid addresses");

        // Store initial state
        uint[4] memory preState = [
            balanceOf[tempUser],
            balanceOf[from],
            balanceOf[to],
            totalSupply
        ];

        emit TransferPreDebug(from, to, value);
        bool success = transfer(to, value);
        assert(success);
        emit TransferPostDebug(from, to, value);

        // Verify state changes
        assert(balanceOf[tempUser] == preState[0]); // Third user's balance unchanged
        assert(balanceOf[from] == preState[1] - value); // Sender's balance decreased
        assert(balanceOf[to] == preState[2] + value); // Recipient's balance increased
        assert(totalSupply == preState[3]); // Total supply unchanged
        // Allowance is not changed by transfer (not transferFrom), so no need to check
    }
    
    function nameAndSymbolShouldBeSame() public view {
        assert(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("BuggyToken20")));
        assert(keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("BUG20")));
    }

    function decimalsShouldBe18() public view {
        assert(decimals == 18);
    }

    function transferFromInvariant(address from, address to, uint value, address tempUser) public {
        address spender = msg.sender;
        require(from != to, "Invalid from and to");
        require(from != tempUser, "Invalid from");
        require(to != tempUser, "Invalid to");
        require(spender != tempUser, "Invalid spender");

        uint preTempUserBalance = balanceOf[tempUser];
        uint preAllowance = allowance[from][spender];
        uint preFromBalance = balanceOf[from];
        uint preToBalance = balanceOf[to];
        uint preTotalSupply = totalSupply;  

        emit TransferFromPreDebug(from, to, value);
        bool success = transferFrom(from, to, value);
        assert(success);
        emit TransferFromPostDebug(from, to, value);
        uint postTempUserBalance = balanceOf[tempUser];
        uint postAllowance = allowance[from][spender];
        uint postFromBalance = balanceOf[from];
        uint postToBalance = balanceOf[to];
        uint postTotalSupply = totalSupply;

        assert(postTempUserBalance == preTempUserBalance); // Third user's balance should not change
        
        // Handle infinite allowance case (type(uint256).max should not be decreased)
        if (preAllowance == type(uint256).max) {
            assert(postAllowance == preAllowance); // Infinite allowance should remain unchanged
        } else {
            assert(postAllowance == preAllowance - value); // Normal allowance should be decreased
        }
        
        assert(postFromBalance == preFromBalance - value);
        assert(postToBalance == preToBalance + value);
        assert(postTotalSupply == preTotalSupply);
    }

    function approveInvariant(address spender, uint value) public {
        address _owner = msg.sender;

        require(spender != _owner, "Invalid spender");

        uint preAllowance = allowance[_owner][spender];
        uint preOwnerBalance = balanceOf[_owner];
        uint preSpenderBalance = balanceOf[spender];
        uint preTotalSupply = totalSupply;

        emit ApprovePreDebug(_owner, spender, value);
        approve(spender, value);
        emit ApprovePostDebug(_owner, spender, value);
        uint postAllowance = allowance[_owner][spender];
        uint postTotalSupply = totalSupply;
        uint postOwnerBalance = balanceOf[_owner];
        uint postSpenderBalance = balanceOf[spender];

        assert(postAllowance == value);
        assert(postTotalSupply == preTotalSupply);
        assert(postOwnerBalance == preOwnerBalance);
        assert(postSpenderBalance == preSpenderBalance);
    }

    function burnInvariant(uint value,address tempUser) public {
        address _owner = msg.sender;
        require(_owner != tempUser, "Invalid owner");

        uint preTotalSupply = totalSupply;
        uint preOwnerBalance = balanceOf[_owner];
        uint preTempUserBalance = balanceOf[tempUser];

        emit BurnPreDebug(_owner, value);
        _burn(_owner,value);
        emit BurnPostDebug(_owner, value);
        uint postTotalSupply = totalSupply;
        uint postOwnerBalance = balanceOf[_owner];
        uint postTempUserBalance = balanceOf[tempUser];

        assert(postTotalSupply == preTotalSupply - value);
        assert(postOwnerBalance == preOwnerBalance - value);

        // no other user should be affected
        assert(postTempUserBalance == preTempUserBalance);
    }


}