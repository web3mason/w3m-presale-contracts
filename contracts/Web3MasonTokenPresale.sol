// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./utils/RecoverableErc20.sol";

contract Web3MasonTokenPresale is Ownable2Step, RecoverableErc20, Pausable {
    using Address for address payable;
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address payable public wallet;
    uint256 public price;

    event TokenSale(address indexed account, uint256 amount, uint256 price);
    event Withdraw(address indexed receiver, uint256 amount);
    event PriceChanged(uint256 oldPrice, uint256 newPrice);
    event WalletChanged(address oldAddress, address newAddress);

    constructor(address token_, address wallet_) {
        token = IERC20(token_);
        price = 1 * 10 ** 11;
        emit PriceChanged(0, price);

        emit WalletChanged(wallet, wallet_);
        wallet = payable(wallet_);
    }

    function reserveToken() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function balanceEth() public view returns (uint256) {
        return address(this).balance;
    }

    function buy() public payable {
        uint256 amountToken = (msg.value * 10 ** 18) / price;
        require(amountToken <= reserveToken(), "Insufficient Token");

        token.safeTransfer(_msgSender(), amountToken);
        emit TokenSale(_msgSender(), amountToken, price);
    }

    receive() external payable {
        buy();
    }

    function pause(bool paused_) external onlyOwner {
        if (paused_) _pause();
        else _unpause();
    }

    function setPrice(uint256 price_) external onlyOwner {
        require(price_ != 0, "Zero price");
        emit PriceChanged(price, price_);
        price = price_;
    }

    function setWallet(address wallet_) external onlyOwner {
        require(wallet_ != address(0), "Zero address");
        emit WalletChanged(wallet, wallet_);
        wallet = payable(wallet_);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= balanceEth(), "Insufficient balance ETH");
        wallet.sendValue(amount);
        emit Withdraw(wallet, amount);
    }
}
