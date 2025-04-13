// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./IPoolBase.sol";
import "hardhat/console.sol";

interface IFoMox {
    function calculateMaxBuyAmount() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract FoPool is Initializable, OwnableUpgradeable, UUPSUpgradeable,ReentrancyGuardUpgradeable,  IPoolBase {
    // 池子存储
    Pool[] public pools;
    mapping(address => uint256) private userAmounts;
    uint256 public totalAmount;
    uint256 public processCount;
    // 设置
    uint256 public minDeposit;
    uint256 public maxPoolPercent; // 池子大小占流动性的最大百分比
    
    // 外部合约
    IFoMox public fomoxContract;
    ERC20Upgradeable public usdtContract;
    IUniswapV2Router02 public router;
    IUniswapV2Pair public uniswapPair;
    
    // 事件
    event PoolDeposit(address indexed user, uint256 amount);
    event OrderProcessed(address indexed user, uint256 amount, uint256 index);
    modifier onlyFomox() {
        require(msg.sender == address(fomoxContract) || msg.sender == owner(), "Only FoMox can call");
        _;
    }
    bool public inSwap;
    
     modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _fomoxAddress,
        address _usdtAddress,
        address _routerAddress,
        address _uniswapPairAddress
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        
        fomoxContract = IFoMox(_fomoxAddress);
        usdtContract = ERC20Upgradeable(_usdtAddress);
        router = IUniswapV2Router02(_routerAddress);
        uniswapPair = IUniswapV2Pair(_uniswapPairAddress);
        
        minDeposit = 50 * 10**18; // 最小50U
        maxPoolPercent = 40; // 最大占流动性的40%
    }
        
    // 防止合约直接接收ETH
    receive() external payable {
        if (msg.value > 0) {
            depositToFoPool();
        }
    }

    function getPools() public view returns (Pool[] memory) {
        return pools;
    }

    // 将BNB存入Fo池 - 修改为使用外部合约
    function depositToFoPool() public payable nonReentrant {
        require(msg.value > 0, "Cannot deposit 0 BNB");
        require(getUserAmount(msg.sender) == 0, "Already deposited in Fo pool");
        require(fomoxContract.balanceOf(msg.sender) == 0, "You have tokens cannot to deposit");
        // 获取用户可以存入的最大金额
        uint256 maxAllowedDeposit = fomoxContract.calculateMaxBuyAmount();
        uint256 bnbAmount = msg.value;
       
        address[] memory path = new address[](2);
        path[0] = address(usdtContract);
        path[1] = router.WETH();
        uint256[]  memory amounts = router.getAmountsOut(maxAllowedDeposit,path );
        uint256 maxWETH = amounts[1];
        uint256 more = 0;
        if (bnbAmount > maxWETH) {
            more = bnbAmount - maxWETH;
            payable(msg.sender).transfer(more);
            bnbAmount = maxWETH;
        }
        
        path[0] = router.WETH();
        path[1] = address(usdtContract);
        
        amounts = router.swapExactETHForTokens{value: bnbAmount}(
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        
        uint256 usdtAmount = amounts[1];
        require(usdtAmount >= minDeposit, "Deposit amount too small");
        
        // // 检查池子大小是否超过限制
        uint256 liquidityUsdt = getUsdtReserve();
        require(totalAmount + usdtAmount <= liquidityUsdt * maxPoolPercent / 100, "Fo pool exceeded liquidity limit");
        require(getUserAmount(msg.sender) + usdtAmount <= maxAllowedDeposit, "Deposit exceeds maximum allowed");
        
        address user = msg.sender;
        pools.push(Pool({
            addr: user,
            usdtAmount: usdtAmount,
            bnbAmount: msg.value
        }));
        
        userAmounts[user] += usdtAmount;
        totalAmount += usdtAmount;
        
        emit PoolDeposit(user, usdtAmount);
         }
    
    function transferBNB(address payable recipient) public onlyOwner {
        require(address(this).balance > 0, "No BNB to transfer");
        recipient.transfer(address(this).balance);
    }
    // 获取USDT流动性池储备
    function getUsdtReserve() public view returns (uint256) {
       (uint256 reserve0, uint256 reserve1,) = uniswapPair.getReserves();
       address token0 = uniswapPair.token0();
       return token0 == address(usdtContract) ? reserve0 : reserve1;
    }

    // 获取FoMox流动性池储备
    function getTokenReserve() public view returns (uint256) {
      (uint256 reserve0, uint256 reserve1,) = uniswapPair.getReserves();
       address token0 = uniswapPair.token0();
       return token0 == address(usdtContract) ? reserve1 :reserve0 ;
    }

    // 实现接口方法
    function deposit(address user, uint256 usdtAmount, uint256 bnbAmount) public virtual override nonReentrant {
     revert("Not allowed");
    }
    
    function getUserAmount(address user) public view override returns (uint256) {
        return userAmounts[user];
    }
    
    function getTotalAmount() public view override returns (uint256) {
        return totalAmount;
    }
    
    function getPoolLength() public view override returns (uint256) {
        return pools.length;
    }
    
    function getPoolAt( ) public view override returns (Pool memory) {
        require(processCount < pools.length, "Index out of bounds");
        return pools[processCount];
    }
    
    function getInSwap() override public view returns (bool) {
        return inSwap;
    }

    function processOrder(address to) public override onlyFomox nonReentrant lockTheSwap returns (bool) {
        if (processCount >= pools.length) return false;

        Pool memory order = pools[processCount];
       
        if (order.usdtAmount == 0) return false;
        
        // 执行买入操作
        usdtContract.approve(address(router), order.usdtAmount);
        
        address[] memory path = new address[](2);
        path[0] = address(usdtContract);
        path[1] = to;
        
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            order.usdtAmount,
            0,
            path,
            order.addr,
            block.timestamp + 300
        );
        removeOrder();
        clearUserDeposit(order.addr);
        processCount++;
        emit OrderProcessed(order.addr, order.usdtAmount, processCount);
        return true;
    }

    function setProcessCount(uint256 _processCount) public onlyOwner {
        require(_processCount <= pools.length, "Invalid process count");
        processCount = _processCount;
    }
    
    function removeOrder() public override onlyFomox {
        if (processCount >= pools.length) return;
        
        Pool memory order = pools[processCount];
        
        // 减少总量和用户存款
        totalAmount -= order.usdtAmount;
         delete userAmounts[order.addr];
        
        // 删除订单
       delete pools[processCount] ;
     }
    
    function clearUserDeposit(address user) public override onlyFomox  {
        userAmounts[user] = 0;
    }
    
    // 设置函数
    function setMinDeposit(uint256 _minDeposit) public onlyOwner {
        minDeposit = _minDeposit;
    }
    
    function setMaxPoolPercent(uint256 _maxPoolPercent) public onlyOwner {
        require(_maxPoolPercent <= 100, "Invalid percentage");
        maxPoolPercent = _maxPoolPercent;
    }
    
    function getProcessedCount() public view returns (uint256) {
        return processCount;
    }

    function setFomoxAddress(address _fomoxAddress) public onlyOwner {
        require(_fomoxAddress != address(0), "Invalid address");
        fomoxContract = IFoMox(_fomoxAddress);
    }

    function setUniswapPair(address _uniswapPair) public onlyOwner {
        require(_uniswapPair != address(0), "Invalid address");
        uniswapPair = IUniswapV2Pair(_uniswapPair);
    }
    
        // 批量转USDT给多个地址 - 添加访问控制
    function batchTransferUsdt(address[] calldata recipients, uint256[] calldata amounts) public  {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");
         // 执行转账
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(usdtContract.transferFrom(msg.sender,recipients[i], amounts[i]), "Transfer failed");
        }
    }

    // UUPS 升级函数
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
