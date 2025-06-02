// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Challlenge01 as Token} from "../src/Challenge01.sol";
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
    constructor() Token("AllInvariants", "ALLINV") {
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


    // this must always hold true
    function totalBalanceShouldNeverBeLessThanUserBalance(address user) public view {
        uint userBalance = balanceOf(user);
        uint totalBalance = totalSupply();
        assert(totalBalance >= userBalance);
    }

    /*
    @
    */
    function transferInvariant(address to, uint value) public {

        // @audit you should 
        // making sure that the to and from are not the same 
        address from = msg.sender;

        require(to != from, "Invalid receiver");
        // pre-state
        uint preBalance = balanceOf(from);
        uint preTotalSupply = totalSupply();
        uint prefromBalance = balanceOf(from);
        uint pretoBalance = balanceOf(to);
        uint preAllowance = allowance(from, to);


        emit TransferPreDebug(from, to, value);
        // action
        bool success = transfer(to, value);
        // assert(success);

        // post-state
        uint postBalance = balanceOf(from);
        uint postTotalSupply = totalSupply();
        uint postFromBalance = balanceOf(from);
        uint postToBalance = balanceOf(to);
        uint postAllowance = allowance(from, to);

        emit TransferPostDebug(from, to, value);
        // assertions
        assert(postBalance == preBalance - value);
        assert(postTotalSupply == preTotalSupply);
        assert(postFromBalance == prefromBalance - value);
        assert(postToBalance == pretoBalance + value);
        assert(postAllowance == preAllowance);
    }
    
    function nameAndSymbolShouldBeSame() public view {
        assert(keccak256(abi.encodePacked(name())) == keccak256(abi.encodePacked("AllInvariants")));
        assert(keccak256(abi.encodePacked(symbol())) == keccak256(abi.encodePacked("ALLINV")));
    }

    function decimalsShouldBe18() public view {
        assert(decimals() == 18);
    }

    function transferFromInvariant(address from, address to, uint value) public {
        address spender = msg.sender;
        require(from != to, "Invalid from and to");
        uint preAllowance = allowance(from, spender);
        uint preFromBalance = balanceOf(from);
        uint preToBalance = balanceOf(to);
        uint preTotalSupply = totalSupply();  

        emit TransferFromPreDebug(from, to, value);
        bool success = transferFrom(from, to, value);
        assert(success);
        emit TransferFromPostDebug(from, to, value);
        uint postAllowance = allowance(from, spender);
        uint postFromBalance = balanceOf(from);
        uint postToBalance = balanceOf(to);
        uint postTotalSupply = totalSupply();

        assert(postAllowance == preAllowance - value);
        assert(postFromBalance == preFromBalance - value);
        assert(postToBalance == preToBalance + value);
        assert(postTotalSupply == preTotalSupply);
    }

    function approveInvariant(address spender, uint value) public {
        address owner = msg.sender;

        require(spender != owner, "Invalid spender");

        uint preAllowance = allowance(owner, spender);
        uint preOwnerBalance = balanceOf(owner);
        uint preSpenderBalance = balanceOf(spender);
        uint preTotalSupply = totalSupply();

        emit ApprovePreDebug(owner, spender, value);
        approve(spender, value);
        emit ApprovePostDebug(owner, spender, value);
        uint postAllowance = allowance(owner, spender);
        uint postTotalSupply = totalSupply();
        uint postOwnerBalance = balanceOf(owner);
        uint postSpenderBalance = balanceOf(spender);

        assert(postAllowance == value);
        assert(postTotalSupply == preTotalSupply);
        assert(postOwnerBalance == preOwnerBalance);
        assert(postSpenderBalance == preSpenderBalance);
    }

    function burnInvariant(uint value,address tempUser) public {
        address owner = msg.sender;
        require(owner != tempUser, "Invalid owner");

        uint preTotalSupply = totalSupply();
        uint preOwnerBalance = balanceOf(owner);
        uint preTempUserBalance = balanceOf(tempUser);

        emit BurnPreDebug(owner, value);
        _burn(owner, value);
        emit BurnPostDebug(owner, value);
        uint postTotalSupply = totalSupply();
        uint postOwnerBalance = balanceOf(owner);
        uint postTempUserBalance = balanceOf(tempUser);

        assert(postTotalSupply == preTotalSupply - value);
        assert(postOwnerBalance == preOwnerBalance - value);

        // no other user should be affected
        assert(postTempUserBalance == preTempUserBalance);
    }


}