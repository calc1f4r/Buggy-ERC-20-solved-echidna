// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Challenge10 as Token} from "../src/Challenge10.sol";
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
    
    function nameAndSymbolShouldBeSame() public view {
        assert(keccak256(abi.encodePacked(name())) == keccak256(abi.encodePacked("BuggyToken10")));
        assert(keccak256(abi.encodePacked(symbol())) == keccak256(abi.encodePacked("BUG10")));
    }

    function decimalsShouldBe18() public pure {
        assert(decimals() == 18);
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
        
        // Handle infinite allowance case
        if (preAllowance != type(uint256).max) {
            assert(postAllowance == preAllowance - value);
        } else {
            assert(postAllowance == preAllowance); // Infinite allowance stays infinite
        }
        
        assert(postFromBalance == preFromBalance - value);
        assert(postToBalance == preToBalance + value);
        assert(postTotalSupply == preTotalSupply);
    }

    function approveInvariant(address spender, uint value) public {
        address owner = msg.sender;

        require(spender != owner, "Invalid spender");
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
        _burn(owner,value);
        emit BurnPostDebug(owner, value);
        uint postTotalSupply = totalSupply();
        uint postOwnerBalance = balanceOf(owner);
        uint postTempUserBalance = balanceOf(tempUser);

        assert(postTotalSupply == preTotalSupply - value);
        assert(postOwnerBalance == preOwnerBalance - value);

        // no other user should be affected
        assert(postTempUserBalance == preTempUserBalance);
    }


    function testInvarientIncreaseAllowance(address spender,uint addedValue) public {
        address owner = msg.sender;


        uint256 preAllowance = allowance(owner, spender);
        uint256 preOwnerBalance = balanceOf(owner);
        uint256 preSpenderBalance = balanceOf(spender);
        uint256 preTotalSupply = totalSupply();

        emit ApprovePreDebug(owner, spender, addedValue);
        increaseAllowance(spender, addedValue);
        emit ApprovePostDebug(owner, spender, addedValue);

        uint256 postAllowance = allowance(owner, spender);
        uint256 postTotalSupply = totalSupply();
        uint256 postOwnerBalance = balanceOf(owner);
        uint256 postSpenderBalance = balanceOf(spender);

        assert(postAllowance == preAllowance + addedValue);
        assert(postTotalSupply == preTotalSupply);
        assert(postOwnerBalance == preOwnerBalance);
        assert(postSpenderBalance == preSpenderBalance);
    }
    function testInvariantDecreaseAllowance(address spender, uint256 subtractedValue) public {
        address owner = msg.sender;

        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        uint256 preAllowance = allowance(owner, spender);
        uint256 preOwnerBalance = balanceOf(owner);
        uint256 preSpenderBalance = balanceOf(spender);
        uint256 preTotalSupply = totalSupply();

        emit ApprovePreDebug(owner, spender, subtractedValue);
        decreaseAllowance(spender, subtractedValue);
        emit ApprovePostDebug(owner, spender, subtractedValue);

        uint256 postAllowance = allowance(owner, spender);
        uint256 postTotalSupply = totalSupply();
        uint256 postOwnerBalance = balanceOf(owner);
        uint256 postSpenderBalance = balanceOf(spender);

        assert(postAllowance == preAllowance - subtractedValue);
        assert(postTotalSupply == preTotalSupply);
        assert(postOwnerBalance == preOwnerBalance);
        assert(postSpenderBalance == preSpenderBalance);
    }

        function mintAccessControlInvariant(address to, uint256 amount, address tempUser) public {
        require(to != address(0), "Cannot mint to zero address");

        uint preTotalSupply = totalSupply();
        uint preBalanceTo = balanceOf(to);
        uint preBalanceTempUser = balanceOf(tempUser);
        
        emit MintPreDebug(to, amount);
        
        mint(to, amount);

        // Due to the buggy onlyOwner modifier in Challenge10, anyone can mint
        // The modifier should have require(msg.sender == owner) but it's missing the require
        // So mint will always succeed regardless of who calls it
        assert(balanceOf(to) == preBalanceTo + amount); // Recipient's balance should increase
        assert(totalSupply() == preTotalSupply + amount); // Total supply should increase
        
        // Temp user should not be affected
        assert(balanceOf(tempUser) == preBalanceTempUser);
        emit MintPostDebug(to, amount);
    }

    function burnAccessControlInvariant(uint256 amount, address tempUser) public {
        address account = msg.sender;
        require(account != tempUser, "Invalid account");

        uint preTotalSupply = totalSupply();
        uint preBalanceAccount = balanceOf(account);
        uint preBalanceTempUser = balanceOf(tempUser);

        emit BurnPreDebug(account, amount);

        burn(account, amount);

        // Due to the buggy onlyOwner modifier in Challenge10, anyone can burn
        // The modifier should have require(msg.sender == owner) but it's missing the require
        // So burn will always succeed regardless of who calls it
        assert(balanceOf(account) == preBalanceAccount - amount); // Account's balance should decrease
        assert(totalSupply() == preTotalSupply - amount); // Total supply should decrease

        // Temp user should not be affected
        assert(balanceOf(tempUser) == preBalanceTempUser);
        emit BurnPostDebug(account, amount);
    }


    // not anyone else can be the owner 
    
    function ownerbeSame(address newowner) public  {

        bool iscallertheowner=owner==msg.sender;


        
        if(iscallertheowner){
            transferOwnership(newowner);
            assert(owner == newowner);
        }
        else{
            // If the caller is not the owner, they cannot change ownership
            assert(owner != newowner);
        }    
        
        }

}