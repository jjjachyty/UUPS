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

contract MoPool is Initializable,ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, IPoolBase {
    // 池子存储
    Pool[] private pools;
    mapping(address => uint256) private userAmounts;
    uint256 private totalAmount;
    uint256 private processCount;
    uint256 public minDeposit;
    
    // 外部合约
    address public fomoxAddress;
    ERC20Upgradeable public usdtContract;
    IUniswapV2Router02 public router;
     
    // 事件
    event PoolDeposit(address indexed user, uint256 amount);
    event OrderProcessed(address indexed user, uint256 amount, uint256 index);
    
    modifier onlyFomox() {
        require(msg.sender == fomoxAddress || msg.sender == owner(), "Only FoMox can call");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _fomoxAddress,
        address _usdtAddress,
        address _routerAddress
     ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        
        fomoxAddress = _fomoxAddress;
        usdtContract = ERC20Upgradeable(_usdtAddress);
        router = IUniswapV2Router02(_routerAddress);
        minDeposit = 5 * 10 ** 18; // 设置最小存款为5 USDT
    }
    
    // 实现接口方法
    function deposit(address user, uint256 usdtAmount, uint256 bnbAmount) external override onlyFomox nonReentrant {
        pools.push(Pool({
            addr: user,
            usdtAmount: usdtAmount,
            bnbAmount: bnbAmount
        }));
        
        userAmounts[user] += usdtAmount;
        totalAmount += usdtAmount;
        
        emit PoolDeposit(user, usdtAmount);
    }
    
    function getUserAmount(address user) external view override returns (uint256) {
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

    //设置最小金额5U
    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        minDeposit = _minDeposit;
    }
    
    function processOrder( address to) external override onlyFomox nonReentrant returns (bool) {
        require(processCount < pools.length, "Index out of bounds");
        
        Pool memory order = pools[processCount];
        if (order.usdtAmount == 0) return false;
        //小于5U则舍弃
        if (order.usdtAmount <= minDeposit){
            removeOrder();
            processCount++;
            return true;
        }
        
        // Mo池直接转账不通过Router交易
        // 由调用者负责完成后续操作
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
        delete userAmounts[order.addr];
        delete pools[processCount];
        processCount++;
        // 删除订单
        return true;
    }
    
    function removeOrder() public override onlyFomox {
        require(processCount < pools.length, "Index out of bounds");
        
        Pool memory order = pools[processCount];
        
        // 减少总量和用户存款
        totalAmount -= order.usdtAmount;
        userAmounts[order.addr] -= order.usdtAmount;
        
        // 删除订单
       delete pools[processCount];
        
    }
    
    function clearUserDeposit(address user) external override onlyFomox {
        userAmounts[user] = 0;
    }
    
    function getProcessCount() external view override returns (uint256) {
        return processCount;
    }

    function setFomoxAddress(address _fomoxAddress) external onlyOwner {
        require(_fomoxAddress != address(0), "Invalid address");
        fomoxAddress = _fomoxAddress;
    }
    
    // UUPS 升级函数
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
