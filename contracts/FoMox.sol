// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FoMox is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
 
    // 常量
    uint256 public constant TOTAL_SUPPLY = 110000000 * 10**18; // 1.1亿枚代币
    uint256 public constant INITIAL_LIQUIDITY = 100000000 * 10**18; // 初始流动性1亿枚
    uint256 public constant INITIAL_USDT = 10000 * 10**18; // 初始1万U

    // PancakeSwap接口
    IUniswapV2Router02 public router;
    address public uniswapPair;
    address public usdtAddress; // USDT合约地址

    // 地址配置
    address public techAddress; // 技术维护地址
    address public ecoAddress; // 生态地址
    address public foPoolRewardAddress; // Fo池分红地址
    address public communityRewardAddress; // 社区奖励地址
    address public fTokenAddress; // F代币地址
 

    // 池子配置
    struct Pool {
        address  addr; // 池子地址
        uint256 usdtAmount; // 池子USDT金额
        uint256 bnbAmount; // 池子BNB总金额
    }

    Pool[] public foPool; // Fo池
    mapping(address => uint256) public foPoolUserAmounts; // 用户在Fo池的存入金额
    uint256 public foPoolTotalAmount; // Fo池总金额
    Pool[] public moPool; // Mo池
    mapping(address => uint256) public moPoolUserAmounts; // 用户在Mo池的存入金额
    uint256 public moPoolTotalAmount; // Mo池总金额

 


    mapping (address=>bool) isExemptFromTransferRestrictions;
    // 用户交易相关
    struct UserInfo {
        uint256 lastBuyTimestamp; // 最后一次买入时间
        uint256 totalBought; // 总买入U数量
    }
    
    mapping(address => UserInfo) public userInfo;
    
    // 推荐关系
    mapping(address => address) public referrers; // 用户的推荐人
    mapping(address => address[]) public referrals; // 用户的直接推荐列表
    mapping(address => uint256) public referralCount; // 用户的直接推荐数量
    
    // 社区长相关
    mapping(address => bool) public isCommunityLeader; // 是否是社区长
    mapping(address => address) public communityLeaderOf; // 用户的社区长地址
    mapping(address => address[]) public communityMembers; // 社区长的所有成员
    

    // 系统参数
    uint256 public foPoolMinDeposit; // Fo池最小入金
    uint256 public buyMaxAmount; // 最大买入金额
    uint256 public buyFeePercent; // 买入总手续费百分比
    uint256 public sellFeePercent; // 卖出总手续费百分比
    uint256 public buyTechFeePercent; // 买入技术维护费比例
    uint256 public sellBurnPercent; // 卖出销毁比例
    uint256 public sellEcoFeePercent; // 卖出生态地址费比例
    uint256 public sellFoPoolFeePercent; // 卖出Fo池分红费比例
    uint256 public sellCommunityFeePercent; // 卖出社区奖励费比例
    uint256 public sellCommunityLeaderFeePercent; // 社区长分红比例
    uint256 public sellMoPoolPercent; // 卖出进入Mo池比例
    uint256 public buyReferralPercent; // 买入推荐奖励总比例
    uint256 public directReferralPercent; // 直推比例
    uint256 public indirectReferralPercent; // 间推比例
    uint256 public maxReferralLevels; // 最大推荐层级
    uint256 public holdingTime; // 持有锁定时间(秒)
    uint256 public profitLimit; // 利润限制倍数
    uint256 public gasLimit; // 交易Gas限制

    // 价格控制参数
    struct PriceControlTier {
        uint256 minLiquidity; // 最小流动性
        uint256 maxLiquidity; // 最大流动性
        uint256 maxDailyIncrease; // 最大日涨幅
        uint256 triggerDecreasePercent; // 触发自动买入的跌幅
    }
    
    PriceControlTier[] public priceControlTiers;
    uint256 public foMoSwapRatio; // Fo池和Mo池交替买入比例
    uint256 public todayStartPrice; // 今日起始价格
    uint256 public currentPrice; // 当前价格

    // 当前状态变量
    uint256 public foProcessedCount; // 已处理的Fo池条目计数
    uint256 public moProcessedCount; // 已处理的Mo池条目计数
      
 
    // 事件
    event FoPoolDeposit(address indexed user, uint256 amount);
    event AutomaticBuy(uint256 amount, bool isFromFoPool);
    event TokenBought(address indexed buyer, uint256 tokenAmount, uint256 usdtAmount);
    event TokenSold(address indexed seller, uint256 tokenAmount, uint256 feeAmount, uint256 feeUsdtAmount);
    event ReferralRegistered(address indexed referrer, address indexed referee);
    event ReferralReward(address indexed user, address indexed referrer, uint256 amount, uint256 level);
    event DailyReset(uint256 timestamp, uint256 startPrice);
    event FoPoolRewardDistributed(uint256 totalAmount);
    event SellAttemptViaTransfer(address indexed user, uint256 amount);
    event BuyAttemptViaTransfer(address indexed user, uint256 amount);
    event CommunityLeaderRegistered(address indexed leader);
    event CommunityLeaderFeeDistributed(address indexed user, address indexed leader, uint256 amount);
    event CommunityLeaderAssigned(address indexed user, address indexed leader);
    event UsdtTransferred(address indexed recipient, uint256 amount);
    event MoPoolDeposit(address indexed user, uint256 amount );
    event ReferralRegisteredWithF(address indexed referrer, address indexed referee);
    event AutoBuyExecuted(uint256 foCount, uint256 moCount, uint256 totalAmount);
    event AutoBuyPaused(string reason);
    event PriceControlTriggered(uint256 currentPrice, uint256 triggerPrice, bool isDropTrigger);
 
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _usdtAddress,
        address _routerAddress,
        address _techAddress,
        address _ecoAddress,
        address _foPoolRewardAddress,
        address _communityRewardAddress
     ) public initializer {
        __ERC20_init("FoMox", "FOMOX");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        usdtAddress = _usdtAddress;
        router = IUniswapV2Router02(_routerAddress);
        techAddress = _techAddress;
        ecoAddress = _ecoAddress;
        foPoolRewardAddress = _foPoolRewardAddress;
        communityRewardAddress = _communityRewardAddress;

        // 设置默认参数
        foPoolMinDeposit = 50 * 10**18; // 最小50U
        buyMaxAmount = 100 * 10**18;   // 默认最大买入100U
        buyFeePercent = 7; // 买入7%手续费
        sellFeePercent = 8; // 卖出8%手续费
        buyTechFeePercent = 3; // 买入3%给技术维护地址
        sellBurnPercent = 2; // 卖出2%销毁
        sellEcoFeePercent = 2; // 卖出2%给生态地址
        sellFoPoolFeePercent = 2; // 卖出2%给Fo池分红
        sellCommunityFeePercent = 1; // 卖出1%给社区奖励
        sellCommunityLeaderFeePercent = 1; // 社区长分红1%
        sellMoPoolPercent = 50; // 卖出50%进入Mo池
        buyReferralPercent = 4; // 买入4%作为推荐奖励
        directReferralPercent = 1; // 直推1%
        indirectReferralPercent = 5; // 间推0.5% * 6级 = 3%
        maxReferralLevels = 7; // 最大7级推荐
        holdingTime = 72 hours; // 72小时锁定期
        profitLimit = 2; // 最多返回2倍投资
        gasLimit = 500000; // 交易Gas限制
        

        foMoSwapRatio = 3; // 默认3单Fo对1单Mo的比例

        // 设置价格控制参数
        setupPriceControlTiers();

        // 铸造总代币
        _mint(address(this), TOTAL_SUPPLY);

        // 创建初始流动性
        createInitialLiquidity();

        // 添加初始例外地址
        isExemptFromTransferRestrictions[address(this)] = true;
        isExemptFromTransferRestrictions[address(0)] = true;
        isExemptFromTransferRestrictions[address(0xdead)] = true;
        isExemptFromTransferRestrictions[_techAddress] = true;
        isExemptFromTransferRestrictions[_ecoAddress] = true;
        isExemptFromTransferRestrictions[_foPoolRewardAddress] = true;
        isExemptFromTransferRestrictions[_communityRewardAddress] = true;
     }

    function setupPriceControlTiers() internal {
        // 清除现有配置
        while(priceControlTiers.length > 0) {
            priceControlTiers.pop();
        }

        // 添加价格控制配置
        priceControlTiers.push(PriceControlTier(
            1 * 10**4 * 10**18, // 1万U
            5 * 10**4 * 10**18, // 5万U
            20, // 最大20%涨幅
            10  // 跌10%触发
        ));
        
        priceControlTiers.push(PriceControlTier(
            5 * 10**4 * 10**18, // 5万U
            10 * 10**4 * 10**18, // 10万U
            15, // 最大15%涨幅
            10  // 跌10%触发
        ));
        
        priceControlTiers.push(PriceControlTier(
            10 * 10**4 * 10**18, // 10万U
            20 * 10**4 * 10**18, // 20万U
            10, // 最大10%涨幅
            5   // 跌5%触发
        ));
        
        priceControlTiers.push(PriceControlTier(
            20 * 10**4 * 10**18, // 20万U
            50 * 10**4 * 10**18, // 50万U
            8,  // 最大8%涨幅
            5   // 跌5%触发
        ));
        
        priceControlTiers.push(PriceControlTier(
            50 * 10**4 * 10**18, // 50万U
            type(uint256).max, // 无上限
            5,  // 最大5%涨幅
            5   // 跌5%触发
        ));
    }
 

    function createInitialLiquidity() internal {
        // 批准路由器使用代币
        _approve(address(this), address(router), INITIAL_LIQUIDITY);
        
       
        
        // 获取创建的交易对地址
        address factory = router.factory();
        uniswapPair = IUniswapV2Factory(factory).createPair(address(this), usdtAddress);
        
        // 设置初始价格
        todayStartPrice = INITIAL_USDT * (10**18) / (INITIAL_LIQUIDITY);
        currentPrice = todayStartPrice;
    }

    // 防止合约直接接收ETH
    receive() external payable {
        if (msg.value > 0) {
            depositToFoPool();
        }
    }

    // 将BNB存入Fo池
    function depositToFoPool() public payable nonReentrant {
        require(msg.value > 0, "Cannot deposit 0 BNB");
        require(foPoolUserAmounts[msg.sender] ==0,"Already deposited in Fo pool");
        require(super.balanceOf(msg.sender) == 0, "You have tokens cannot to deposit");

        // 先将BNB换成USDT
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = usdtAddress;
        
        uint256[] memory amounts = router.swapExactETHForTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        
        uint256 usdtAmount = amounts[1];
        require(usdtAmount >= foPoolMinDeposit, "Deposit amount too small");
        
        // 检查池子大小是否超过限制
        uint256 liquidityUsdt = getUsdtReserve();
        require(foPoolTotalAmount + usdtAmount <= liquidityUsdt * 40 / 100, "Fo pool exceeded 40% of liquidity");
        
        // 获取用户可以存入的最大金额
        uint256 maxAllowedDeposit = calculateMaxBuyAmount();
        require(foPoolUserAmounts[msg.sender]+usdtAmount <= maxAllowedDeposit, "Deposit exceeds maximum allowed");
       

        foPool.push(Pool({
            addr: msg.sender,
            usdtAmount: usdtAmount,
            bnbAmount: msg.value
        }));
        foPoolTotalAmount += usdtAmount;
        foPoolUserAmounts[msg.sender] += usdtAmount;
        
        emit FoPoolDeposit(msg.sender, usdtAmount);
    }

    // 根据底池等级计算最大买入金额
    function calculateMaxBuyAmount() public view returns (uint256) {
        uint256 liquidityUsdt = getUsdtReserve();
        
        if (liquidityUsdt < 3 * 10**4 * 10**18) {
            return 100 * 10**18;
        } else if (liquidityUsdt >= 3 * 10**4 * 10**18 && liquidityUsdt < 5 * 10**4 * 10**18) {
            return 200 * 10**18;
        } else if (liquidityUsdt >= 5 * 10**4 * 10**18 && liquidityUsdt < 7 * 10**4 * 10**18) {
            return 300 * 10**18;
        } else if (liquidityUsdt >= 7 * 10**4 * 10**18 && liquidityUsdt < 9 * 10**4 * 10**18) {
            return 400 * 10**18;
        } else if (liquidityUsdt >= 9 * 10**4 * 10**18 && liquidityUsdt < 11 * 10**4 * 10**18) {
            return 500 * 10**18;
        } else if (liquidityUsdt >= 11 * 10**4 * 10**18 && liquidityUsdt < 13 * 10**4 * 10**18) {
            return 600 * 10**18;
        } else if (liquidityUsdt >= 13 * 10**4 * 10**18 && liquidityUsdt < 15 * 10**4 * 10**18) {
            return 700 * 10**18;
        } else if (liquidityUsdt >= 15 * 10**4 * 10**18 && liquidityUsdt < 17 * 10**4 * 10**18) {
            return 800 * 10**18;
        } else if (liquidityUsdt >= 17 * 10**4 * 10**18 && liquidityUsdt < 19 * 10**4 * 10**18) {
            return 900 * 10**18;
        } else if (liquidityUsdt >= 19 * 10**4 * 10**18) {
            return 1000 * 10**18;
        }  
    }

    // 获取USDT流动性池储备
    function getUsdtReserve() public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniswapPair).getReserves();
        return address(this) < usdtAddress ? reserve1 : reserve0;
    }

    // 获取FoMox流动性池储备
    function getTokenReserve() public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniswapPair).getReserves();
        return address(this) < usdtAddress ? reserve0 : reserve1;
    }

    // 获取当前价格
    function getCurrentPrice() public view returns (uint256) {
        uint256 usdtReserve = getUsdtReserve();
        uint256 tokenReserve = getTokenReserve();
        if (tokenReserve == 0) return 0;
        return usdtReserve * (10**18) / (tokenReserve);
    }

    // 检查日涨幅是否超过限制
    function checkDailyPriceLimit() public view returns (bool) {
        uint256 currentPriceVal = getCurrentPrice();
        uint256 liquidityUsdt = getUsdtReserve();
        uint256 maxIncreasePct;
        
        for (uint256 i = 0; i < priceControlTiers.length; i++) {
            if (liquidityUsdt >= priceControlTiers[i].minLiquidity && 
                liquidityUsdt < priceControlTiers[i].maxLiquidity) {
                maxIncreasePct = priceControlTiers[i].maxDailyIncrease;
                break;
            }
        }
        
        // 检查今日涨幅
        uint256 maxPrice = todayStartPrice + (todayStartPrice * maxIncreasePct / 100);
        return currentPriceVal <= maxPrice;
    }

    // 检查价格下跌是否触发自动买入
    function checkAutoBuyTrigger() public view returns (bool) {
        uint256 currentPriceVal = getCurrentPrice();
        uint256 liquidityUsdt = getUsdtReserve();
        uint256 triggerPct;
        
        for (uint256 i = 0; i < priceControlTiers.length; i++) {
            if (liquidityUsdt >= priceControlTiers[i].minLiquidity && 
                liquidityUsdt < priceControlTiers[i].maxLiquidity) {
                triggerPct = priceControlTiers[i].triggerDecreasePercent;
                break;
            }
        }
        
        // 检查价格下跌触发自动买入
        uint256 minPrice = todayStartPrice - (todayStartPrice * triggerPct / 100);
        return currentPriceVal < minPrice;
    }

 

    //
    function setTodayStartPrice() public onlyOwner{
        // 更新今日开始价格
        todayStartPrice = getCurrentPrice();
    }

    function checkAddressEffect(address addr) public view returns (bool) {
        return balanceOf(addr)>0 || foPoolUserAmounts[addr]>0 || moPoolUserAmounts[addr]>0;
    }

    // 处理推荐奖励
    function processReferralRewards(address user, uint256 totalReferralFee) internal nonReentrant {
        if (totalReferralFee == 0) return;
        
        address currentRef = referrers[user];
        uint256 directFee = totalReferralFee * (directReferralPercent) / (buyReferralPercent);
        uint256 indirectFeePerLevel = totalReferralFee *(indirectReferralPercent) / (buyReferralPercent) / (maxReferralLevels - 1);
        
        uint256 distributedFee = 0;
        uint256 currentLevel = 1;
        
        // 处理直推奖励
        if (currentRef != address(0) && !isExemptFromTransferRestrictions[currentRef]) {
            if (checkAddressEffect(currentRef)) {
                ERC20Upgradeable(usdtAddress).transfer(currentRef, directFee);
                distributedFee = distributedFee + (directFee);
                emit ReferralReward(user, currentRef, directFee, 1);
            }
            // 处理间接推荐奖励
            currentRef = referrers[currentRef];
            currentLevel++;
            
            while (currentRef != address(0) && currentRef != uniswapPair && currentLevel <= maxReferralLevels) {
                if (referralCount[currentRef] >= currentLevel - 1 && checkAddressEffect(currentRef)) {
                    ERC20Upgradeable(usdtAddress).transfer(currentRef, indirectFeePerLevel);
                    distributedFee = distributedFee + (indirectFeePerLevel);
                    emit ReferralReward(user, currentRef, indirectFeePerLevel, currentLevel);
                }
                
                currentRef = referrers[currentRef];
                currentLevel++;
            }
        }
        
        // 剩余未分配的奖励发送给社区奖励地址
        uint256 remainingFee = totalReferralFee - (distributedFee);
        if (remainingFee > 0) {
            ERC20Upgradeable(usdtAddress).transfer(communityRewardAddress, remainingFee);
        }
    }

 
    // 将资金添加到Mo池，允许同一用户多次入队
    function addToMoPool(address sender, uint256 amount) internal nonReentrant {
        // 添加到Mo池队列
        moPool.push(Pool({
            addr: sender,
            usdtAmount: amount,
            bnbAmount: 0
        }));
        moPoolTotalAmount += amount;
        moPoolUserAmounts[sender] += amount;
        // 发出事件记录
        emit MoPoolDeposit(sender, amount);
    }
 

    // 注册推荐关系并设置社区长
    function transferAndRegisterReferral(address from, address to) public nonReentrant {
        require(msg.sender == owner() || msg.sender == fTokenAddress, "Only owner or FToken can call this");
        require(!isExemptFromTransferRestrictions[to], "Invalid referrer address");
        
        // 注册推荐关系
        referrers[msg.sender] = to;
        referrals[to].push(msg.sender);
        referralCount[to] = referralCount[to] + 1;
        
        // 处理社区长关系
        _assignCommunityLeader(msg.sender, to);
        
        emit ReferralRegistered(to, msg.sender);
    }
    
    // 内部函数：分配社区长给用户
    function _assignCommunityLeader(address user, address referrer) internal {
        // 判断推荐人是否是社区长
        if (isCommunityLeader[referrer]) {
            // 如果推荐人是社区长，直接设置
            communityLeaderOf[user] = referrer;
            communityMembers[referrer].push(user);
        } else if (communityLeaderOf[referrer] != address(0)) {
            // 如果推荐人有社区长，继承相同的社区长
            address leader = communityLeaderOf[referrer];
            communityLeaderOf[user] = leader;
            communityMembers[leader].push(user);
        } else {
            // 如果都不是，用户暂时没有社区长
            revert("No community leader assigned");
        }
    }
    
 
    
    // 检查是否可以购买
    function checkCanBuy() public view returns (bool) {
        // 根据底池U检查当前是否可以购买
        uint256 liquidityUsdt = getUsdtReserve();
        uint256 currentPriceVal = getCurrentPrice();
        if (liquidityUsdt <= 5 * 10**4 * 10**18 && currentPriceVal <  (todayStartPrice * 120 / 100)) {
            return true;
        }else if (liquidityUsdt > 5 * 10**4 * 10**18 && liquidityUsdt < 10 * 10**4 * 10**18 && currentPriceVal < (todayStartPrice * 115 / 100)) {
            return true;
        }else if (liquidityUsdt > 10 * 10**4 * 10**18 && liquidityUsdt < 20 * 10**4 * 10**18 && currentPriceVal < (todayStartPrice * 110 / 100)) {
            return true;
        }else if (liquidityUsdt > 20 * 10**4 * 10**18 && liquidityUsdt < 50 * 10**4 * 10**18 && currentPriceVal < (todayStartPrice * 108 / 100)) {
            return true;
        }else if (liquidityUsdt > 50 * 10**4 * 10**18 && currentPriceVal < (todayStartPrice * 105 / 100)) { 
            return true;
        }
        return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        return _buySell(sender,recipient, amount);
    }
    function _buySell(address sender,
        address recipient,
        uint256 amount) internal virtual   returns (bool){

   
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // 判断是否是与Uniswap的交互
        bool isSell = recipient == uniswapPair;
        bool isBuy = sender == uniswapPair;
        
            // 如果是用户要卖出代币到Uniswap，自动调用sellTokens
            if (isSell) {
                // 取消当前transfer操作，改为调用sellTokens
                _autoSellTokens(sender, amount);
                 return true;
            }
            
            // 如果是用户要从Uniswap买入代币，自动调用buyTokens
            if (isBuy) {
                 
                // 取消当前transfer操作，改为调用buyTokens
                _autoBuyTokens(recipient, amount);
                
                 return true;
            }
        revert("Transfer not allowed");
    }
    // 重写transfer函数，强制使用buyTokens和sellTokens
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        return _buySell(msg.sender,recipient, amount);
    }
    
    // 添加内部自动卖出函数
    function _autoSellTokens(address seller, uint256 amount) internal {
        //合约卖币不扣手续费
        if (msg.sender == address(this)) {
            super._transfer(seller, address(this), amount);
            return;
        }
        // 记录调用者的代币余额
        uint256 tokenBalance = balanceOf(seller);
        require(tokenBalance >= amount, "Insufficient balance");
              
        // 检查持有时间
        require(block.timestamp >= userInfo[seller].lastBuyTimestamp + holdingTime, "Holding time not met");

        // 检查利润限制
        uint256 maxAllowedProfit = userInfo[seller].totalBought * profitLimit;
        // 计算用户2倍需要多少Token
        uint256 tokenNeed = getUSDTToTokenAmount(usdtAddress,address(this), maxAllowedProfit);
        uint256 communityMoreFee = 0;
        if (amount > tokenNeed) {
            communityMoreFee = amount - tokenNeed;
        }
        
        // 计算费用并执行转账
        uint256 burnAmount = amount * sellBurnPercent / 100;
        
        // 转移代币到合约
        super._transfer(seller, address(this), amount-burnAmount);
        
        // 计算剩余费用
        _processSellFees(seller, amount, burnAmount, communityMoreFee);
    }
    
    // 辅助函数：处理卖出费用
    function _processSellFees(address seller, uint256 amount, uint256 burnAmount, uint256 communityMoreFee) private {
        // 计算各种费用
        uint256 ecoFee = amount * sellEcoFeePercent / 100;
        uint256 foPoolFee = amount * sellFoPoolFeePercent / 100;
        uint256 communityFee = amount * sellCommunityFeePercent / 100;
        uint256 leaderFee = amount * sellCommunityLeaderFeePercent / 100;
        uint256 moPoolFee = amount * sellMoPoolPercent / 100;
        
        // 计算总费用
        uint256 totalFees = ecoFee + foPoolFee + communityFee + leaderFee + moPoolFee + communityMoreFee;
        
        // 批准路由器使用代币
        _approve(address(this), address(router), totalFees);
        
        // 卖出代币获取USDT
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdtAddress;
        
        uint256[] memory amounts = router.swapExactTokensForTokens(
            totalFees,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        
        // 用户最终得到的USDT
        uint256 feeUSDTReceived = amounts[1];
        
        // 处理销毁
        if (burnAmount > 0) {
            super.transfer(address(0xdead), burnAmount);
        }
        
        // 分配所有费用
        _distributeSellFees(seller, ecoFee, foPoolFee, communityFee, leaderFee, moPoolFee, communityMoreFee, totalFees, feeUSDTReceived);
        
        emit TokenSold(seller, amount, totalFees, feeUSDTReceived);
    }
    
    // 辅助函数：分配卖出费用
    function _distributeSellFees(
        address seller,
        uint256 ecoFee, 
        uint256 foPoolFee, 
        uint256 communityFee, 
        uint256 leaderFee, 
        uint256 moPoolFee,
        uint256 communityMoreFee,
        uint256 totalFees,
        uint256 feeUSDTReceived
    ) private {
        // 超过2倍利润限制
        if (communityMoreFee > 0) {
            ERC20Upgradeable(usdtAddress).transfer(communityRewardAddress, feeUSDTReceived*communityMoreFee/totalFees);
        }
        
        // 发送生态费用
        if (ecoFee > 0) {
            ERC20Upgradeable(usdtAddress).transfer(ecoAddress, feeUSDTReceived*ecoFee/totalFees);
        }
        
        // 发送Fo池分红费用
        if (foPoolFee > 0) {
            ERC20Upgradeable(usdtAddress).transfer(foPoolRewardAddress, feeUSDTReceived*foPoolFee/totalFees);
        }
        
        // 发送社区奖励费用
        if (communityFee > 0) {
            ERC20Upgradeable(usdtAddress).transfer(communityRewardAddress, feeUSDTReceived*communityFee/totalFees);
        }
        
        // 处理社区长费用
        _processCommunityLeaderFee(seller, leaderFee, totalFees, feeUSDTReceived);
        
        // 添加到Mo池
        addToMoPool(seller, feeUSDTReceived*moPoolFee/totalFees);
    }
    
    // 辅助函数：处理社区长费用
    function _processCommunityLeaderFee(address seller, uint256 leaderFee, uint256 totalFees, uint256 feeUSDTReceived) private {
        if (leaderFee > 0) {
            address leader = communityLeaderOf[seller];
            uint256 leaderUSDTFee = feeUSDTReceived*leaderFee/totalFees;
            if (leader != address(0)) {
                ERC20Upgradeable(usdtAddress).transfer(leader, leaderUSDTFee);
                emit CommunityLeaderFeeDistributed(seller, leader, leaderUSDTFee);
            } else {
                // 如果用户没有社区长，转给社区奖励地址
                ERC20Upgradeable(usdtAddress).transfer(communityRewardAddress, leaderUSDTFee);
            }
        }
    }
    
    //根据币种获取兑换USDT的数量
    function getTokenToUSDTAmount(address from,address to,uint amountIn) public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;

        uint[] memory amounts = router.getAmountsOut(amountIn, path);
        return amounts[1]; // 返回兑换出的 USDT 数量
    }
    function getUSDTToTokenAmount(address from,address to,uint amountOut) public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;

        uint[] memory amounts = router.getAmountsIn(amountOut, path);
        return amounts[1]; // 返回兑换出的 USDT 数量
    }
    // 添加内部自动买入函数
    function _autoBuyTokens(address buyer, uint256 amount) internal {
        // 由于从Uniswap买入是router直接转账给用户
        // 这种情况下我们需要监测router的交易并模拟buyTokens操作
        
        // 检查价格是否已超过日涨幅限制
        require(checkDailyPriceLimit(), "Price already reached daily limit");
        require(super.balanceOf(buyer) == 0, "You have tokens cannot to buy");
        require(foPoolUserAmounts[buyer]==0, "Already deposited in Fo pool");
        require(moPoolUserAmounts[buyer]==0, "Already deposited in Mo pool");

        
        // 计算要扣除的手续费
        uint256 techFee = amount * buyTechFeePercent / 100;
        uint256 referralFee = amount * buyReferralPercent / 100;
        uint256 usdtAmount = getTokenToUSDTAmount(address(this), usdtAddress, amount);
        // 更新用户购买信息
        userInfo[buyer].lastBuyTimestamp = block.timestamp;
        userInfo[buyer].totalBought = userInfo[buyer].totalBought + usdtAmount;
        
        // 完成原始转账
        super._transfer(uniswapPair, buyer, amount);
        
        // 提醒用户通过正确方式购买
        emit TokenBought(buyer, amount, usdtAmount);
    }

    // 批量转USDT给多个地址
    function batchTransferUsdt(address[] calldata recipients, uint256[] calldata amounts) public {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");
        
        ERC20Upgradeable usdt = ERC20Upgradeable(usdtAddress);
        // 执行转账
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            usdt.transfer(recipients[i], amounts[i]);
        }
    }
  
    // 设置Fo池最小入金额
    function setFoPoolMinDeposit(uint256 _foPoolMinDeposit) external onlyOwner {
        foPoolMinDeposit = _foPoolMinDeposit;
    }
    
    // 设置买入费用比例
    function setBuyFeePercent(uint256 _buyFeePercent) external onlyOwner {
        buyFeePercent = _buyFeePercent;
    }
    
    // 设置卖出费用比例
    function setSellFeePercent(uint256 _sellFeePercent) external onlyOwner {
        sellFeePercent = _sellFeePercent;
    }
    
    // 设置买入技术维护费比例
    function setBuyTechFeePercent(uint256 _buyTechFeePercent) external onlyOwner {
        buyTechFeePercent = _buyTechFeePercent;
    }
    
    // 设置卖出销毁比例
    function setSellBurnPercent(uint256 _sellBurnPercent) external onlyOwner {
        sellBurnPercent = _sellBurnPercent;
    }
    
    // 设置卖出生态地址费比例
    function setSellEcoFeePercent(uint256 _sellEcoFeePercent) external onlyOwner {
        sellEcoFeePercent = _sellEcoFeePercent;
    }
    
    // 设置卖出Fo池分红费比例
    function setSellFoPoolFeePercent(uint256 _sellFoPoolFeePercent) external onlyOwner {
        sellFoPoolFeePercent = _sellFoPoolFeePercent;
    }
    
    // 设置卖出社区奖励费比例
    function setSellCommunityFeePercent(uint256 _sellCommunityFeePercent) external onlyOwner {
        sellCommunityFeePercent = _sellCommunityFeePercent;
    }
    
    // 设置卖出进入Mo池比例
    function setSellMoPoolPercent(uint256 _sellMoPoolPercent) external onlyOwner {
        sellMoPoolPercent = _sellMoPoolPercent;
    }
    
    // 设置买入推荐奖励总比例
    function setBuyReferralPercent(uint256 _buyReferralPercent) external onlyOwner {
        buyReferralPercent = _buyReferralPercent;
    }
    
    // 设置直推比例
    function setDirectReferralPercent(uint256 _directReferralPercent) external onlyOwner {
        directReferralPercent = _directReferralPercent;
    }
    
    // 设置间推比例
    function setIndirectReferralPercent(uint256 _indirectReferralPercent) external onlyOwner {
        indirectReferralPercent = _indirectReferralPercent;
    }
    
    // 设置最大推荐层级
    function setMaxReferralLevels(uint256 _maxReferralLevels) external onlyOwner {
        maxReferralLevels = _maxReferralLevels;
    }
    
    // 设置持有锁定时间
    function setHoldingTime(uint256 _holdingTime) external onlyOwner {
        holdingTime = _holdingTime;
    }
    
    // 设置利润限制倍数
    function setProfitLimit(uint256 _profitLimit) external onlyOwner {
        profitLimit = _profitLimit;
    }
    
    // 设置Fo池和Mo池交替买入比例
    function setFoMoSwapRatio(uint256 _foMoSwapRatio) external onlyOwner {
        foMoSwapRatio = _foMoSwapRatio;
    }
    
    // 单独设置各地址
    
    // 设置技术维护地址
    function setTechAddress(address _techAddress) external onlyOwner {
        require(_techAddress != address(0), "Invalid address");
        techAddress = _techAddress;
    }
    
    // 设置生态地址
    function setEcoAddress(address _ecoAddress) external onlyOwner {
        require(_ecoAddress != address(0), "Invalid address");
        ecoAddress = _ecoAddress;
    }
    
    // 设置Fo池分红地址
    function setFoPoolRewardAddress(address _foPoolRewardAddress) external onlyOwner {
        require(_foPoolRewardAddress != address(0), "Invalid address");
        foPoolRewardAddress = _foPoolRewardAddress;
    }
    
    // 设置社区奖励地址
    function setCommunityRewardAddress(address _communityRewardAddress) external onlyOwner {
        require(_communityRewardAddress != address(0), "Invalid address");
        communityRewardAddress = _communityRewardAddress;
    }
    
  
    
    // 更新地址配置
    function updateAddresses(
        address _techAddress,
        address _ecoAddress,
        address _foPoolRewardAddress,
        address _communityRewardAddress,
        address _projectAddress
    ) external onlyOwner {
        require(_techAddress != address(0) && 
                _ecoAddress != address(0) && 
                _foPoolRewardAddress != address(0) && 
                _communityRewardAddress != address(0) && 
                _projectAddress != address(0), "Invalid address");
                
        techAddress = _techAddress;
        ecoAddress = _ecoAddress;
        foPoolRewardAddress = _foPoolRewardAddress;
        communityRewardAddress = _communityRewardAddress;
     }
    
    // 管理员功能
    
    // 更新价格控制参数
    function updatePriceControlTiers(
        uint256[] calldata minLiquidities,
        uint256[] calldata maxLiquidities,
        uint256[] calldata maxDailyIncreases,
        uint256[] calldata triggerDecreasePercents
    ) external onlyOwner {
        require(minLiquidities.length == maxLiquidities.length &&
                minLiquidities.length == maxDailyIncreases.length &&
                minLiquidities.length == triggerDecreasePercents.length,
                "Arrays must have the same length");
        
        // 清除现有配置
        while(priceControlTiers.length > 0) {
            priceControlTiers.pop();
        }
        
        // 添加新配置
        for (uint256 i = 0; i < minLiquidities.length; i++) {
            priceControlTiers.push(PriceControlTier(
                minLiquidities[i],
                maxLiquidities[i],
                maxDailyIncreases[i],
                triggerDecreasePercents[i]
            ));
        }
    }
    
    
    // 添加完整流动性的函数
    function addInitialLiquidity() external onlyOwner {
        require(uniswapPair != address(0), "Pair not created yet");
        require(ERC20Upgradeable(address(this)).balanceOf(address(this)) >= INITIAL_LIQUIDITY, "Insufficient token balance");
        
        // 批准路由器使用代币
        _approve(address(this), address(router), INITIAL_LIQUIDITY);
        
        // 创建USDT/FoMox交易对并添加流动性
        router.addLiquidity(
            address(this),
            usdtAddress,
            INITIAL_LIQUIDITY,
            INITIAL_USDT,
            INITIAL_LIQUIDITY,
            INITIAL_USDT,
            address(this),
            block.timestamp + 300
        );
        
        // 更新当前价格
        todayStartPrice = INITIAL_USDT * (10**18) / (INITIAL_LIQUIDITY);
        currentPrice = todayStartPrice;
    }
    
    // 紧急提取错误发送到合约的代币
    function emergencyWithdraw(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(tokenAddress != address(this), "Cannot withdraw contract tokens");
        
        if (tokenAddress == address(0)) {
            // 提取ETH
            payable(owner()).transfer(amount);
        } else {
            // 提取ERC20代币
            ERC20Upgradeable(tokenAddress).transfer(owner(), amount);
        }
    }
    
    
    // 设置社区长地址
    function registerCommunityLeader(address leader) external onlyOwner {
        require(leader != address(0), "Invalid address");
        isCommunityLeader[leader] = true;
        emit CommunityLeaderRegistered(leader);
    }
    
    // 撤销社区长身份
    function unregisterCommunityLeader(address leader) external onlyOwner {
        require(isCommunityLeader[leader], "Not a community leader");
        isCommunityLeader[leader] = false;
    }
    
    // 手动设置用户的社区长
    function setCommunityLeader(address user, address leader) external onlyOwner {
        require(user != address(0) && leader != address(0), "Invalid address");
        require(isCommunityLeader[leader], "Not a registered community leader");
        
        // 移除用户与旧社区长的关系（如果有）
        address oldLeader = communityLeaderOf[user];
        if (oldLeader != address(0)) {
            _removeFromCommunityLeader(user, oldLeader);
        }
        
        // 设置新社区长
        communityLeaderOf[user] = leader;
        communityMembers[leader].push(user);
        
        emit CommunityLeaderAssigned(user, leader);
    }
    
    // 从社区长成员列表中移除用户
    function _removeFromCommunityLeader(address user, address leader) internal {
        address[] storage members = communityMembers[leader];
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == user) {
                // 找到用户，将其与列表最后一个元素交换，然后移除最后一个元素
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
    }
    
    // 设置社区长分红比例
    function setCommunityLeaderFeePercent(uint256 _percent) external onlyOwner {
         sellCommunityLeaderFeePercent = _percent;
    }
    
    // 获取社区长的所有成员
    function getCommunityMembers(address leader) external view returns (address[] memory) {
        return communityMembers[leader];
    }
    
    // 获取社区长成员数量
    function getCommunityMemberCount(address leader) external view returns (uint256) {
        return communityMembers[leader].length;
    }
    
    // 必须实现的UUPSUpgradeable钩子
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setGasLimit(uint256 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
    }


    // 执行自动买入，根据价格控制和3:1比例买入Fo池和Mo池的订单
    function executeAutoBuy(bool isResetTime) public onlyOwner()  {         
        // 获取当前价格和底池大小
        uint256 currentPriceVal = getCurrentPrice();
        uint256 liquidityUsdt = getUsdtReserve();
        
        // 获取当前价格控制参数
        (uint256 maxIncreasePct, uint256 triggerPct) = getCurrentPriceControlParams(liquidityUsdt);
        
        // 计算最高允许价格和触发价格
        uint256 maxPrice = todayStartPrice + (todayStartPrice * maxIncreasePct / 100);
        uint256 triggerPrice = todayStartPrice - (todayStartPrice * triggerPct / 100);
        //如果是8点直接拉满 不是则补到触发价
        uint256 stopPrice = maxPrice;
        if (!isResetTime) {
            stopPrice = triggerPrice;
        }

        if (currentPriceVal >= stopPrice) {
             emit PriceControlTriggered(currentPriceVal, stopPrice, true);
             return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 count = 3;
        // 处理队列，直到价格达到每日上限或队列为空
        while (currentPriceVal < stopPrice && gasUsed < gasLimit) {
             //取三单Fo池订单
            uint256 fl =  foPool.length;
            uint256 ml = moPool.length;
           
            if (fl == 0 && ml == 0) {
                break;
            }
            // 处理Fo池订单
            while(count>0 && fl > 0){
                count--;
                    Pool memory foOrder = foPool[foProcessedCount];
                    if (foOrder.usdtAmount > 0) {
                         ERC20Upgradeable(usdtAddress).approve(address(router), foOrder.usdtAmount);

                        // 执行买入
                        address[] memory path = new address[](2);
                        path[0] = usdtAddress;
                        path[1] = address(this);
                        router.swapExactTokensForTokens(
                            foOrder.usdtAmount,
                            0,
                            path,
                            foOrder.addr,
                            block.timestamp + 300
                        );
                        foProcessedCount++;
                        delete foPoolUserAmounts[foOrder.addr];
                        delete foPool[foProcessedCount];
                        foPoolTotalAmount -= foOrder.usdtAmount;
                        fl--;
                } else {
                    break;
                }
                
            }
            // 处理Mo池订单
            while((count==0||count==3) && ml > 0 ){
                count=3;
                     Pool memory moOrder = moPool[moProcessedCount];
                    if (moOrder.usdtAmount > 0) {
                        // 执行买入
                        uint256 tokenAmount = getUSDTToTokenAmount(usdtAddress, address(this), moOrder.usdtAmount);
                        super._transfer(address(this), moOrder.addr, tokenAmount);
                        emit TokenBought(moOrder.addr, tokenAmount, moOrder.usdtAmount);
                        moProcessedCount++;
                        delete moPoolUserAmounts[moOrder.addr];
                        delete moPool[moProcessedCount];
                        moPoolTotalAmount -= moOrder.usdtAmount;
                        ml--;
                    } else {
                        break;
                    }
                
            }

             // 更新当前价格
             currentPriceVal = getCurrentPrice();


            // 按3:1比例处理Fo池和Mo池订单
             uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed+(gasLeft - (newGasLeft));
            }

        gasLeft = newGasLeft;
        }
    }
    
    // 获取当前价格控制参数
    function getCurrentPriceControlParams(uint256 liquidityUsdt) public view returns (uint256 maxIncreasePct, uint256 triggerPct) {
        for (uint256 i = 0; i < priceControlTiers.length; i++) {
            if (liquidityUsdt >= priceControlTiers[i].minLiquidity && 
                liquidityUsdt < priceControlTiers[i].maxLiquidity) {
                maxIncreasePct = priceControlTiers[i].maxDailyIncrease;
                triggerPct = priceControlTiers[i].triggerDecreasePercent;
                return (maxIncreasePct, triggerPct);
            }
        }
        
        // 默认使用最后一档
        if (priceControlTiers.length > 0) {
             return (priceControlTiers[0].maxDailyIncrease, priceControlTiers[0].triggerDecreasePercent);
        }
        
        revert("No price control tiers defined");
    }
    
   
    
    // 重置处理计数器 - 当需要重新处理所有队列时使用
    function resetProcessedCounters() external onlyOwner {
        foProcessedCount = 0;
        moProcessedCount = 0;
    }
}
