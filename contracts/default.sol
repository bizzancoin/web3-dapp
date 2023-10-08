pragma solidity ^0.8.0;

// 导入Polygon链上的ERC20接口
import {IERC20} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract USDTExchange {
    address public owner;
    IERC20 public usdt; // USDT代币合约地址

    event Buy(address indexed buyer, uint256 amount, uint256 cost);
    event Sell(address indexed seller, uint256 amount, uint256 earnings);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(address _usdtAddress) {
        owner = msg.sender;
        usdt = IERC20(_usdtAddress);
    }

    // 允许合约接收ETH支付
    receive() external payable {}

    // 用户购买USDT，需要发送ETH作为手续费
    function buy(uint256 usdtAmount) external payable {
        require(msg.value > 0, "You need to send some Ether as fee");
        require(usdtAmount > 0, "Invalid USDT amount");

        // 计算ETH总费用，确保用户支付足够的手续费
        uint256 totalEthFee = msg.value;
        require(totalEthFee >= calculateFee(usdtAmount), "Insufficient fee provided");

        // 转移USDT给用户
        require(usdt.transferFrom(owner, msg.sender, usdtAmount), "USDT transfer failed");

        // 触发购买事件
        emit Buy(msg.sender, usdtAmount, totalEthFee);
    }

    // 用户卖出USDT，获得ETH作为交换
    function sell(uint256 usdtAmount) external {
        require(usdtAmount > 0, "Invalid USDT amount");
        require(usdt.balanceOf(msg.sender) >= usdtAmount, "Insufficient USDT balance");

        // 转移USDT给合约
        require(usdt.transferFrom(msg.sender, owner, usdtAmount), "USDT transfer failed");

        // 计算ETH收益
        uint256 ethEarnings = calculateEarnings(usdtAmount);

        // 转移ETH给用户
        (bool success, ) = msg.sender.call{value: ethEarnings}("");
        require(success, "ETH transfer failed");

        // 触发卖出事件
        emit Sell(msg.sender, usdtAmount, ethEarnings);
    }

    // 计算购买手续费，你可以根据需要进行调整
    function calculateFee(uint256 usdtAmount) internal pure returns (uint256) {
        // 这里可以根据需要设置手续费规则，例如按照交易额的百分比收取手续费
        // 这里简单地将手续费设置为1%的ETH
        return (usdtAmount * 1) / 100;
    }

    // 计算卖出ETH收益，你可以根据需要进行调整
    function calculateEarnings(uint256 usdtAmount) internal pure returns (uint256) {
        // 这里可以根据需要设置收益规则，例如按照交易额的百分比计算ETH收益
        // 这里简单地将ETH收益设置为卖出USDT数量的1%
        return (usdtAmount * 1) / 100;
    }

    // 合约所有者可以提取合约内的ETH余额
    function withdrawEth() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // 合约所有者可以提取合约内的USDT余额
    function withdrawUsdt() external onlyOwner {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        require(usdt.transfer(owner, usdtBalance), "USDT withdrawal failed");
    }
}
