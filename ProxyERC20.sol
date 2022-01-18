// SPDX-License-Identifier: MIT



/**
 In short, this is an abstract contract that allows a specified wallet to perform actions such as transfer, approve and sell
 on any ERC20-compliant token held by a contract. 

 All you need to do is call it from etherscan/whatever from the wallet you specified and put the token contract address in, and fill the rest out as normal.

 This also includes a stub Wrapped Ether withdraw function, in case you get WETH stuck in your contract somehow.
    
 I had to include the Context, IUniswapV2Router02, IERC20 interfaces etc. As these are used in many other normal contracts, I've suffixed them with 4Proxy
 as I don't expect copy/paste devs to be able to work out how to remove them safely. 

 I included a sellAndSend function call as not all token contracts may include the ability to withdraw raw ETH. I also included a raw ETH withdrawal.

 You MUST trust your ERC20 controller. 
    
*/
pragma solidity ^0.8.11;

abstract contract Context4Proxy {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// Generic IERC20 interface, given we want to work with ERC20 tokens.
// Stripped down to reduce code requirements.
interface IERC204Proxy {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

}
// Stripped-down router interface
interface IUniswapV2Router024Proxy {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

}
// As code size is important, I'm reducing libs to what is necessary.
library stubSafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}


// Stripped-down IWETH9 interface to withdraw
interface IWETH94Proxy is IERC204Proxy {

    function withdraw(uint wad) external;

}

// Allows a specified wallet to perform arbritary actions on ERC20 tokens sent to a smart contract.
abstract contract ProxyERC20 is Context4Proxy {
    using stubSafeMath for uint256;
    address private _controller;
    IUniswapV2Router024Proxy _router;
    constructor() {
        // TODO: Set this to be who you want to control your ERC20 tokens.
        _controller = address(0);
        _router = IUniswapV2Router024Proxy(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }
    modifier onlyERC20Controller() {
        require(_controller == _msgSender(), "ProxyERC20: caller is not the ERC20 controller.");
        _;
    }

    // Sends an approve to the erc20Contract
    function proxiedApprove(address erc20Contract, address spender, uint256 amount) external onlyERC20Controller() returns (bool) {
        IERC204Proxy theContract = IERC204Proxy(erc20Contract);
        return theContract.approve(spender, amount);
    }

    // Transfers from the contract to the recipient
    function proxiedTransfer(address erc20Contract, address recipient, uint256 amount) external onlyERC20Controller() returns (bool) {
        IERC204Proxy theContract = IERC204Proxy(erc20Contract);
        return theContract.transfer(recipient, amount);
    }
    // Sells all tokens of erc20Contract.
    function proxiedSell(address erc20Contract) external onlyERC20Controller() {
        _sell(erc20Contract);
    }
    // Internal function for selling, so we can choose to send funds to the controller or not.
    function _sell(address add) internal {
        IERC204Proxy theContract = IERC204Proxy(add);
        address[] memory path = new address[](2);
        path[0] = add;
        path[1] = _router.WETH();
        uint256 tokenAmount = theContract.balanceOf(address(this));
        theContract.approve(address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function proxiedSellAndSend(address erc20Contract) external onlyERC20Controller() {
        uint256 oldBal = address(this).balance;
        _sell(erc20Contract);
        uint256 amt = address(this).balance.sub(oldBal);
        // We implicitly trust the ERC20 controller. Send it the ETH we got from the sell.
        sendValue(payable(_controller), amt);
    }
    // Withdraw ETH. Maybe your contract doesn't have it in there already?
    function withdrawETH() external onlyERC20Controller() {
        uint256 amt = address(this).balance;
        sendValue(payable(_controller), amt);
    }

    // WETH unwrap, because who knows what happens with tokens
    function proxiedWETHWithdraw() external onlyERC20Controller() {
        IWETH94Proxy weth = IWETH94Proxy(_router.WETH());
        uint256 bal = weth.balanceOf(address(this));
        weth.withdraw(bal);
    }

    // This is the sendValue taken from OpenZeppelin's Address library. It does not protect against reentrancy! 
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

}