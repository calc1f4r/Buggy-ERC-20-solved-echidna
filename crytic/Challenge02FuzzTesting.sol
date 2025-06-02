// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Challenge02 as Token} from "../src/Challenge02.sol";
// import {Challlenge01 as Token} from "../src/Challenge01.sol";
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
    constructor() Token("AllInvariants", "ALLINV", 18) {
        // Initialize the contract with some tokens
        owner = msg.sender;
    }
    //////////////// minting Invariants ////////////////////
    function mintInvariant(address to, uint256 amount) public {
        require(to != address(0), "Cannot mint to zero address");

        uint256 preBalance = balanceOf[to];
        uint256 preTotalSupply = totalSupply;

        emit MintPreDebug(to, amount);
        _mint(to, amount);
        emit MintPostDebug(to, amount);
        uint256 postTotalSupply = totalSupply;
        uint256 postBalance = balanceOf[to];
        assert(postBalance == preBalance + amount);
        assert(postTotalSupply == preTotalSupply + amount);
    }


    // this must always hold true
    function totalBalanceShouldNeverBeLessThanUserBalance(address user) public view {
        uint256 userBalance = balanceOf[user];
        uint256 totalBalance = totalSupply;
        assert(totalBalance >= userBalance);
    }

    /*
    @
    */
    function transferInvariant(address to, uint256 value) public {
        // making sure that the to and from are not the same 
        address from = msg.sender;

        require(to != from, "Invalid receiver");
        // pre-state
        uint256 preTotalSupply = totalSupply;
        uint256 prefromBalance = balanceOf[from];
        uint256 pretoBalance = balanceOf[to];
        uint256 preAllowance = allowance[from][to];

        // Precondition check for H01
        require(prefromBalance >= value, "Transfer: sender balance too low (H01)");

        emit TransferPreDebug(from, to, value);
        // action
        bool success = transfer(to, value);
        assert(success);

        // post-state
        uint256 postTotalSupply = totalSupply;
        uint256 postFromBalance = balanceOf[from];
        uint256 postToBalance = balanceOf[to];
        uint256 postAllowance = allowance[from][to];

        emit TransferPostDebug(from, to, value);
        // assertions
        assert(postTotalSupply == preTotalSupply);
        assert(postFromBalance == prefromBalance - value);
        assert(postToBalance == pretoBalance + value);
        assert(postAllowance == preAllowance);
    }
    
    function nameAndSymbolShouldBeSame() public view {
        assert(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("AllInvariants")));
        assert(keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("ALLINV")));
    }

    function decimalsShouldBe18() public view {
        assert(decimals == 18);
    }

    function transferFromInvariant(address from, address to, uint256 value) public {
        address spender = msg.sender;
        require(from != to, "Invalid from and to");
        uint256 preAllowance = allowance[from][spender];
        uint256 preFromBalance = balanceOf[from];
        uint256 preToBalance = balanceOf[to];
        uint256 preTotalSupply = totalSupply;  

        // Precondition checks for H02
        require(preFromBalance >= value, "TransferFrom: 'from' balance too low (H02)");
        require(preAllowance >= value, "TransferFrom: allowance too low (H02)");

        emit TransferFromPreDebug(from, to, value);
        bool success = transferFrom(from, to, value);
        assert(success);
        emit TransferFromPostDebug(from, to, value);
        uint256 postAllowance = allowance[from][spender];
        uint256 postFromBalance = balanceOf[from];
        uint256 postToBalance = balanceOf[to];
        uint256 postTotalSupply = totalSupply;

        assert(postAllowance == preAllowance - value);
        assert(postFromBalance == preFromBalance - value);
        assert(postToBalance == preToBalance + value);
        assert(postTotalSupply == preTotalSupply);
    }


    function approveInvariant(address spender, uint256 value, address tempUser) public {
        address owner = msg.sender;

        require(spender != owner, "Invalid spender");
        require(owner != tempUser, "Invalid owner");

        // Track only essential state changes
        uint256 preOwnerAllowance = allowance[owner][spender];
        uint256 preTempUserAllowance = allowance[tempUser][spender];

        // First approval - owner approves for themselves
        emit ApprovePreDebug(owner, spender, value);
        approve(owner, spender, value);
        emit ApprovePostDebug(owner, spender, value);

        // Second approval - owner tries to approve for tempUser
        emit ApprovePreDebug(tempUser, spender, value);
        approve(tempUser, spender, value);
        emit ApprovePostDebug(tempUser, spender, value);

        // Check final state
        uint256 postOwnerAllowance = allowance[owner][spender];
        uint256 postTempUserAllowance = allowance[tempUser][spender];

        // Assertions
        assert(postOwnerAllowance == value); // Owner's approval should be set
        assert(postTempUserAllowance == value); // tempUser's approval should also be set, showing the access control issue
    }

    function burnInvariant(uint256 value, address tempUser) public {
        address owner = msg.sender;
        require(owner != tempUser, "Invalid owner");

        uint256 preTotalSupply = totalSupply;
        uint256 preOwnerBalance = balanceOf[owner];
        uint256 preTempUserBalance = balanceOf[tempUser];

        emit BurnPreDebug(owner, value);
        _burn(owner, value);
        emit BurnPostDebug(owner, value);
        uint256 postTotalSupply = totalSupply;
        uint256 postOwnerBalance = balanceOf[owner];
        uint256 postTempUserBalance = balanceOf[tempUser];

        assert(postTotalSupply == preTotalSupply - value);
        assert(postOwnerBalance == preOwnerBalance - value);

        // no other user should be affected
        assert(postTempUserBalance == preTempUserBalance);
    }

    

    
}