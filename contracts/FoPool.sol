// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./IPoolBase.sol";
import "hardhat/console.sol";

interface IFoMox {
    function calculateMaxBuyAmount() external view returns (uint256);
}


contract FoPool is Initializable,ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, IPoolBase {
    // 池子存储
    Pool[] private pools;
    mapping(address => uint256) private userAmounts;
    uint256 private totalAmount;
    uint256 private processCount;
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
        __Ownable_init();
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

    // 将BNB存入Fo池 - 修改为使用外部合约
    function depositToFoPool() public payable nonReentrant {
        require(msg.value > 0, "Cannot deposit 0 BNB");
        require(getUserAmount(msg.sender) == 0, "Already deposited in Fo pool");
        require(super.balanceOf(msg.sender) == 0, "You have tokens cannot to deposit");

        // 先将BNB换成USDT
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(usdtContract);
        
        uint256[] memory amounts = router.swapExactETHForTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        
        uint256 usdtAmount = amounts[1];
        require(usdtAmount >= minDeposit, "Deposit amount too small");
        
        // 检查池子大小是否超过限制
        uint256 liquidityUsdt = getUsdtReserve();
        require(totalAmount + usdtAmount <= liquidityUsdt * 40 / 100, "Fo pool exceeded 40% of liquidity");
        
        // 获取用户可以存入的最大金额
        uint256 maxAllowedDeposit = fomoxContract.calculateMaxBuyAmount();

    
        require(getUserAmount(msg.sender) + usdtAmount <= maxAllowedDeposit, "Deposit exceeds maximum allowed");
        
        require(usdtAmount >= minDeposit, "Deposit amount too small");
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
    

        // 获取USDT流动性池储备
    function getUsdtReserve() public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1,) =  uniswapPair.getReserves();
        return address(this) < address(usdtContract) ? reserve1 : reserve0;
    }

    // 获取FoMox流动性池储备
    function getTokenReserve() public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1,) = uniswapPair.getReserves();
        return address(this) < address(usdtContract) ? reserve0 : reserve1;
    }

    // 实现接口方法
    function deposit(address user, uint256 usdtAmount, uint256 bnbAmount) public virtual override nonReentrant {
     revert("Not allowed");
    }
    
    function getUserAmount(address user) public view override returns (uint256) {
        return userAmounts[user];
    }
    
    function getTotalAmount() external view override returns (uint256) {
        return totalAmount;
    }
    
    function getPoolLength() external view override returns (uint256) {
        return pools.length;
    }
    
    function getPoolAt( ) external view override returns (Pool memory) {
        require(processCount < pools.length, "Index out of bounds");
        return pools[processCount];
    }
    
    function processOrder(address to) external override onlyFomox nonReentrant returns (bool) {
                     console.log(
        "depositToFoPool %s %s",
        processCount,
        pools.length
    );
        require(processCount < pools.length, "Index out of bounds");

        Pool memory order = pools[processCount];

        if (order.usdtAmount == 0) return false;
        
        // 执行买入操作
        usdtContract.approve(address(router), order.usdtAmount);
        
        address[] memory path = new address[](2);
        path[0] = address(usdtContract);
        path[1] = to;
        
        router.swapExactTokensForTokens(
            order.usdtAmount,
            0,
            path,
            order.addr,
            block.timestamp + 300
        );
         
        emit OrderProcessed(order.addr, order.usdtAmount, processCount);
        processCount++;
        return true;
    }
    
    function removeOrder() external override onlyFomox {
        require(processCount < pools.length, "Index out of bounds");
        
        Pool memory order = pools[processCount];
        
        // 减少总量和用户存款
        totalAmount -= order.usdtAmount;
        userAmounts[order.addr] -= order.usdtAmount;
        
        // 删除订单
       delete pools[processCount] ;
     }
    
    function clearUserDeposit(address user) external override onlyFomox {
        userAmounts[user] = 0;
    }
    
    // 设置函数
    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        minDeposit = _minDeposit;
    }
    
    function setMaxPoolPercent(uint256 _maxPoolPercent) external onlyOwner {
        require(_maxPoolPercent <= 100, "Invalid percentage");
        maxPoolPercent = _maxPoolPercent;
    }
    
    function getProcessCount() external view returns (uint256) {
        return processCount;
    }

    function setFomoxAddress(address _fomoxAddress) external onlyOwner {
        require(_fomoxAddress != address(0), "Invalid address");
        fomoxContract =  IFoMox(_fomoxAddress);
    }
    
    // UUPS 升级函数
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
