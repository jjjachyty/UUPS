// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IPoolBase.sol";
 
contract FoMox is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable  {

     // 常量
    uint256 public constant TOTAL_SUPPLY = 10000000 * 10**18; // 1亿枚代币
    uint256 public constant INITIAL_USDT = 10000 * 10**18; // 初始1万U
    address public usdtAddress; // USDT合约地址
    uint256 public minMoPoolDeposit; // 最小Mo池存款金额
    // 地址配置
    address public techAddress; // 技术维护地址
    address public ecoAddress; // 生态地址
    address public foPoolRewardAddress; // Fo池分红地址
    address public communityRewardAddress; // 社区奖励地址 1%
    IFtoken public fTokenContract; // F代币地址
    IUniswapV2Router02 public router;
    // 池子相关声明
    IPoolBase public foPoolContract;
    IPoolBase public moPoolContract;


    
    mapping (address => bool) public whiteAddress; 
    mapping (address => bool) public blackAddress;

    // 用户交易相关
    struct UserInfo {
        uint256 lastBuyTimestamp; // 最后一次买入时间
        uint256 totalBought; // 总买入U数量
    }
    
    mapping(address => UserInfo) public userInfo;
    // 系统参数
    uint256 public minDeposit; // 最小存款金额
    uint256 public buyMaxAmount; // 最大买入金额
    uint256 public buyFeePercent; // 买入总手续费百分比
    uint256 public buyTechFeePercent; // 买入技术维护费比例 %2
    uint256 public sellFeePercent; // 卖出总手续费百分比
    uint256 public sellTechFeePercent; // 卖出技术维护费比例
    uint256 public sellBurnPercent; // 卖出销毁比例
    uint256 public sellEcoFeePercent; // 卖出生态地址费比例
    uint256 public sellFoPoolFeePercent; // 卖出Fo池分红费比例
    uint256 public sellCommunityFeePercent; // 卖出社区奖励费比例
    uint256 public sellCommunityLeaderFeePercent; // 社区长分红比例
    uint256 public sellMoPoolPercent; // 卖出进入Mo池比例
    uint256 public holdingTime; // 持有锁定时间(秒)
    uint256 public profitLimit; // 利润限制倍数
    uint256 public gasLimit; // 交易Gas限制
    struct LiquidityThreshold {
        uint256 threshold;
        uint256 maxBuyAmount;
    }
    LiquidityThreshold[10] public liquidityThresholds;
    // 价格控制参数
    struct PriceControlTier {
        uint256 minLiquidity; // 最小流动性
        uint256 maxLiquidity; // 最大流动性
        uint256 maxDailyIncrease; // 最大日涨幅
        uint256 triggerDecreasePercent; // 触发自动买入的跌幅
    }
    PriceControlTier[] public priceControlTiers;
    uint256 public todayStartPrice; // 今日起始价格
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

       // 必须实现的UUPSUpgradeable钩子
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initialize(
        address _usdtAddress,
        address _routerAddress,
        address _techAddress,
        address _ecoAddress,
        address _foPoolRewardAddress,
        address _communityRewardAddress,
        address _foPoolAddress,
        address _moPoolAddress,
        address _fTokenAddress
     ) public initializer {
        __ERC20_init("FoMox", "FOMOX");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        usdtAddress = _usdtAddress;
        router = IUniswapV2Router02(_routerAddress);
        techAddress = _techAddress;
        ecoAddress = _ecoAddress;
        foPoolRewardAddress = _foPoolRewardAddress;
        communityRewardAddress = _communityRewardAddress;
        foPoolContract = IPoolBase(_foPoolAddress);
        moPoolContract = IPoolBase(_moPoolAddress);
        fTokenContract = IFtoken(_fTokenAddress);
        // 设置默认参数
        _setupDefaultParameters();
        
        // 设置价格控制参数
        setupPriceControlTiers();
        initializeLiquidityThresholds();
        // 铸造总代币
        _mint(msg.sender, TOTAL_SUPPLY);

 
        whiteAddress[address(this)] = true;
        whiteAddress[owner()] = true;
        whiteAddress[techAddress] = true;
        whiteAddress[ecoAddress] = true;
        whiteAddress[foPoolRewardAddress] = true;
        whiteAddress[communityRewardAddress] = true;
        whiteAddress[address(_fTokenAddress)] = true; // 添加交易对到白名单
     }

    function _setupDefaultParameters() internal {
        minDeposit = 50 * 10**18; // 最小50U
        buyMaxAmount = 100 * 10**18;   // 默认最大买入100U
        buyFeePercent = 7; // 买入7%手续费
        buyTechFeePercent = 2;//技术方
        sellTechFeePercent = 2; // 卖出2%技术维护费
        sellFeePercent = 59; // 卖出10%手续费 2%销毁 2%～ 销毁（代币进黑洞）2%～FO 分红（晚上手动设置）2%～社区奖励（其中 1% 时时给社区地址，1% 归项目方地址）2%～技术方（指定地址）2%～生态基金（指定地址）
        sellBurnPercent = 2; // 卖出2%销毁
        sellEcoFeePercent = 2; // 卖出2%给生态地址
        sellFoPoolFeePercent = 2; // 卖出2%给Fo池分红
        sellCommunityFeePercent = 1; // 卖出1%给社区奖励
        sellCommunityLeaderFeePercent = 1; // 社区长分红1%
        sellMoPoolPercent = 50; // 卖出40%进入Mo池
        holdingTime = 72 hours; // 72小时锁定期
        profitLimit = 2; // 最多返回2倍投资
        gasLimit = 500000; // 交易Gas限制
        minMoPoolDeposit = 5 * 10**18; // 最小Mo池存款金额
     }

  function setupPriceControlTiers() internal {
        // 清除现有配置
        while(priceControlTiers.length > 0) {
            priceControlTiers.pop();
        }

        // 添加价格控制配置
        priceControlTiers.push(PriceControlTier(
            0, // 1万U
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

    // 辅助函数：处理卖出费用
    function _processSellFees(address seller, uint256 usdtAmount) private {
        // 计算各种费用 0.24 20
        uint256 ecoFee = usdtAmount * sellEcoFeePercent / sellFeePercent;
        uint256 foPoolFee = usdtAmount * sellFoPoolFeePercent/ sellFeePercent;
         uint256 leaderFee = usdtAmount * sellCommunityLeaderFeePercent/ sellFeePercent;
        // 计算技术维护费用
        uint256 techFee = usdtAmount * sellTechFeePercent / sellFeePercent;
        uint256 leftAmount = usdtAmount - ecoFee - foPoolFee - techFee - leaderFee;
        //先扣完手续费后 再50%
        uint256 moPoolFee = leftAmount * sellMoPoolPercent/ sellFeePercent;
        // 分配所有费用
        _distributeSellFees(seller, ecoFee, foPoolFee,   leaderFee, moPoolFee,techFee);
    }
    // 辅助函数：分配卖出费用
    function _distributeSellFees(
        address seller,
        uint256 ecoFee, 
        uint256 foPoolFee, 
         uint256 leaderFee, 
        uint256 moPoolFee,
         uint256 techFee
            ) private {
        
        // 发送生态费用
        if (ecoFee > 0) {
            ERC20Upgradeable(usdtAddress).transfer(ecoAddress,ecoFee);
        }
        
        // 发送Fo池分红费用
        if (foPoolFee > 0) {
            ERC20Upgradeable(usdtAddress).transfer(foPoolRewardAddress, foPoolFee);
        }
        // 发送社区长费用
        if (leaderFee > 0) {
            ERC20Upgradeable(usdtAddress).transfer(address(fTokenContract), leaderFee);
              // 处理社区长费用
            fTokenContract.processCommunityLeaderFee(seller, leaderFee);
        }
        if (techFee > 0) {
            // 发送技术维护费用
            ERC20Upgradeable(usdtAddress).transfer(techAddress, techFee);
        }
        if (moPoolFee > minMoPoolDeposit) {
            // 添加到Mo池
             addToMoPool(seller,  moPoolFee);

        }else{
            // 直接转账给社区奖励地址
            ERC20Upgradeable(usdtAddress).transfer(communityRewardAddress, moPoolFee);
        }
    }


function buy(address user,uint256 usdtAmount) public returns(bool) {
    address sender = msg.sender;
    require(sender == address(foPoolContract) || sender == address(moPoolContract) , "Only FoPool or MoPool can call this function");
    bool success =  ERC20Upgradeable(usdtAddress).transferFrom(sender, address(this), usdtAmount);
   if (success) {
        buyUseUSDT(user, usdtAmount);
        return true;
    }
    return false;
}

  function balanceOf(address _address) public view virtual override returns (uint256) {
        uint256 orgBalance = super.balanceOf(_address);
        if (userInfo[_address].totalBought > 0) {
            uint256 maxUSDT =  userInfo[_address].totalBought * profitLimit;
            uint256 needAmount = getUSDTToToken(maxUSDT);
            if (orgBalance > needAmount) {
                return needAmount;
            }
        }
        return orgBalance;
    }

    function getUSDTToToken(
        uint256 usdtAmount
    ) public view returns (uint256) {
        // 获取当前价格
        uint256 currentPrice = getCurrentPrice();
        // 计算输出金额
        return (usdtAmount / currentPrice) / 10**18;
    }

    function getTokenToUSDT(
        uint256 tokenAmount
    ) public view returns (uint256) {
        // 获取当前价格
        uint256 currentPrice = getCurrentPrice();
        // 计算输出金额
        return (tokenAmount * currentPrice) / 10**18;
    }

 function deposit() payable public   {
    address sender = msg.sender;
    require(msg.value > 0, "Cannot deposit 0 BNB");
        require(userInfo[sender].totalBought == 0, "Already bought");
        require(
            msg.sender ==address(moPoolContract) ||
                moPoolContract.getUserAmount(sender) == 0,"Already in MoPool");
        require(
            msg.sender ==address(foPoolContract) ||
                foPoolContract.getUserAmount(sender) == 0, "Already in FoPool"
        );

        address[] memory path = new address[](2);
        path[1] = usdtAddress ;
        path[0] =  router.WETH();
        uint256[]  memory amounts = router.getAmountsOut(calculateMaxBuyAmount(),path);
        uint256 maxWETH = amounts[1];
        uint256 more = 0;
        uint256 bnbAmount = msg.value;
        if (msg.value > maxWETH) {
            more = bnbAmount - maxWETH;
            payable(msg.sender).transfer(more);
            bnbAmount = maxWETH;
        }

        path[0] = router.WETH();
        path[1] = address(usdtAddress);
        
        amounts = router.swapExactETHForTokens{value: bnbAmount}(
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        uint256 usdtAmount = amounts[1];
        buyUseUSDT(sender, usdtAmount);
    }


    function buyUseUSDT(address sender,uint256 usdtAmount) internal{
              require(usdtAmount >= minDeposit, "Amount must be greater than minDeposit");
        require(
            usdtAmount <= calculateMaxBuyAmount(),
            "Amount exceeds max buy limit"
        );
        uint256 amount =  getUSDTToToken(usdtAmount);
        // 计算手续费
        uint256 referralFee = (usdtAmount * buyFeePercent) / 100;
        uint256 buyTechFee = (usdtAmount * buyTechFeePercent) / 100;
 
        userInfo[sender] = UserInfo({
            totalBought: usdtAmount,
            lastBuyTimestamp: block.timestamp
        });
        
        ERC20Upgradeable(usdtAddress).transfer(
            address(fTokenContract),
            referralFee + buyTechFee
        ); // 将手续费转给合约
        super.transfer(sender, amount*(100-buyFeePercent+buyTechFeePercent)/100); // 将剩余部分转给用户
        //触发分红
        fTokenContract.distributeReferralRewards(sender,usdtAmount);
    }

    function balanceOfOrg(address _owner) public view returns (uint256) {
        return super.balanceOf(_owner);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public  override returns (bool) {
        revert("Transfer not allowed");
    }

    // 重写transfer函数，强制使用buyTokens和sellTokens
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        return _sell(msg.sender,recipient, amount);
    }


    // 添加内部自动卖出函数
    function _autoSellTokens(address seller,address to, uint256 amount) internal  {
        // 记录调用者的代币余额
        uint256 tokenBalance = super.balanceOf(seller);
        uint256 moreFee = 0;
        require(amount<=tokenBalance,"Abnormal amount");
        
        // 检查持有时间 - 修复计算方式
        require(userInfo[seller].lastBuyTimestamp>0 && block.timestamp >= userInfo[seller].lastBuyTimestamp + holdingTime, "Holding time not met");
        
        // 检查是否超过最大买入金额
        // 检查利润限制
        uint256 maxAllowedProfit = userInfo[seller].totalBought * profitLimit;
        uint256 maxProfitLimit =  getUSDTToToken( maxAllowedProfit);
        uint256 realAmount = amount;

        if (amount > maxProfitLimit) {
            realAmount = maxProfitLimit;
        }

        if (tokenBalance > amount) {
            moreFee = tokenBalance - realAmount;
        }
        
        // 计算费用并执行转账
        uint256 burnAmount = realAmount * sellBurnPercent / 100; //2%
        uint256 totalFee = realAmount * sellFeePercent / 100; //9%
         // 燃烧部分代币
         _processSellFees(seller, getTokenToUSDT(realAmount));
        if (burnAmount > 0 || moreFee > 0) {
            super._transfer(seller, address(0xdead), burnAmount + moreFee);
        }
        // 计算实际转账金额
        super._transfer(seller, address(this), realAmount-totalFee);
       
        // 清除用户信息
        delete userInfo[seller];
    }
 
    function setWhiteAddress(address _addr, bool _flag) public onlyOwner {
        require(_addr != address(0), "Invalid address");
         whiteAddress[_addr] = _flag;
    }


    function getCommunityRewardAddress() public view returns (address) {
        return communityRewardAddress;
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
            if (liquidityUsdt > priceControlTiers[i].minLiquidity && 
                liquidityUsdt <= priceControlTiers[i].maxLiquidity) {
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
            if (liquidityUsdt > priceControlTiers[i].minLiquidity && 
                liquidityUsdt <= priceControlTiers[i].maxLiquidity) {
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
 
    // 将资金添加到Mo池 - 修改为使用外部合约
    function addToMoPool(address sender, uint256 amount) internal {
        // 批准USDT转账给Mo池合约
        ERC20Upgradeable(usdtAddress).transfer(address(moPoolContract), amount);
        // 发送USDT到用户地址
        ERC20Upgradeable(usdtAddress).transfer(sender, amount);
        // 调用外部合约进行存款
        moPoolContract.deposit(sender, amount, 0);
    }
    

    // 获取FoMox流动性池储备
    function getTokenReserve() public view returns (uint256) {
        return super.balanceOf(address(this));
    }
    // 获取USDT储备
    function getUsdtReserve() public view returns (uint256) {
        return ERC20Upgradeable(usdtAddress).balanceOf(address(this));
    }

     // 根据底池等级计算最大买入金额
    function calculateMaxBuyAmount() public view returns (uint256) {
        uint256 liquidityUsdt = getUsdtReserve();

        for (uint256 i = 0; i < liquidityThresholds.length; i++) {
            if (liquidityUsdt < liquidityThresholds[i].threshold) {
                return liquidityThresholds[i].maxBuyAmount;
            }
        }
        return liquidityThresholds[liquidityThresholds.length - 1].maxBuyAmount;
    }


    // 设置FToken地址
    function setFTokenAddress(address _fTokenAddress) public onlyOwner {
        require(_fTokenAddress != address(0), "Invalid address");
        fTokenContract = IFtoken(_fTokenAddress);
    }
    
    function setBuyTechFeePercent(uint256 _buyFeePercent) public onlyOwner{
        buyTechFeePercent = _buyFeePercent;
    }
    function _sell(address sender, address recipient, uint256 amount) internal   returns (bool) {
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // 白名单地址检查
        if (whiteAddress[sender] || whiteAddress[recipient]) {
            super._transfer(sender, recipient, amount);
            return true;
        }
        
        if (blackAddress[sender] || blackAddress[recipient]) {
            revert("Blacklisted address");
        }
        // 卖出逻辑
        if (recipient ==address(this)) {
             _autoSellTokens(sender, recipient, amount);
              return true;
        }
        
        // 其他转账不允许
        revert("Transfer not allowed");
    }
     
    function initializeLiquidityThresholds() public onlyOwner {
        liquidityThresholds[0] = LiquidityThreshold(3 * 10**4 * 10**18, 100 * 10**18);
        liquidityThresholds[1] = LiquidityThreshold(5 * 10**4 * 10**18, 200 * 10**18);
        liquidityThresholds[2] = LiquidityThreshold(7 * 10**4 * 10**18, 300 * 10**18);
        liquidityThresholds[3] = LiquidityThreshold(9 * 10**4 * 10**18, 400 * 10**18);
        liquidityThresholds[4] = LiquidityThreshold(11 * 10**4 * 10**18, 500 * 10**18);
        liquidityThresholds[5] = LiquidityThreshold(13 * 10**4 * 10**18, 600 * 10**18);
        liquidityThresholds[6] = LiquidityThreshold(15 * 10**4 * 10**18, 700 * 10**18);
        liquidityThresholds[7] = LiquidityThreshold(17 * 10**4 * 10**18, 800 * 10**18);
        liquidityThresholds[8] = LiquidityThreshold(19 * 10**4 * 10**18, 900 * 10**18);
        liquidityThresholds[9] = LiquidityThreshold(type(uint256).max, 1000 * 10**18);
    }
    

    // 获取当前价格控制参数
    function getCurrentPriceControlParams(
        uint256 liquidityUsdt
    ) public view returns (uint256 maxIncreasePct, uint256 triggerPct) {
        uint256 tiersLength = priceControlTiers.length;
        require(tiersLength > 0, "No price control tiers defined");
        // 查找适用的档位
        for (uint256 i = 0; i < tiersLength; i++) {
            if (
                liquidityUsdt > priceControlTiers[i].minLiquidity &&
                liquidityUsdt <= priceControlTiers[i].maxLiquidity
            ) {
                return (
                    priceControlTiers[i].maxDailyIncrease,
                    priceControlTiers[i].triggerDecreasePercent
                );
            }
        }

        // 如果没有找到匹配的档位，使用最后一档
        return (
            priceControlTiers[tiersLength - 1].maxDailyIncrease,
            priceControlTiers[tiersLength - 1].triggerDecreasePercent
        );
    }


    // 执行自动买入 - 修改为使用外部合约
    function executeAutoBuy(bool isResetTime) public onlyOwner() {         
        // 获取当前价格和底池大小
        uint256 currentPriceVal = getCurrentPrice();
        uint256 liquidityUsdt = getUsdtReserve();
        
        // 获取当前价格控制参数
        (uint256 maxIncreasePct, uint256 triggerPct) = getCurrentPriceControlParams(liquidityUsdt);
         // 计算最高允许价格和触发价格
        uint256 maxPrice = todayStartPrice + (todayStartPrice * maxIncreasePct / 100);
        uint256 triggerPrice = todayStartPrice + (todayStartPrice * triggerPct / 100);
        //如果是8点直接拉满 不是则补到触发价
        uint256 stopPrice = maxPrice;
        if (!isResetTime) {
            stopPrice = triggerPrice;
        }
 
        if (currentPriceVal >= stopPrice) {
              return;
        }

 
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 count = 3;
        
        // 处理队列，直到价格达到每日上限或队列为空
        while (getCurrentPrice() < stopPrice && gasUsed < gasLimit) {
            count = 3;
            // 取三单Fo池订单
            uint256 fl = foPoolContract.getPoolLength() - foPoolContract.getProcessedCount();
            uint256 ml = moPoolContract.getPoolLength() - moPoolContract.getProcessedCount();
           
            if (fl == 0 && ml == 0) {
                break;
            }
            
            // 处理Fo池订单
            while(count > 0 && fl > 0 && getCurrentPrice() < stopPrice ){
                 count--;
                bool success = foPoolContract.processOrder();
                if (success) {
                    fl--;
                } else {
                    break;
                }
            }
            
            // 处理Mo池订单
            if(ml >0 && getCurrentPrice() < stopPrice ){
                bool success = moPoolContract.processOrder();
                if (success) {
                     count = 1;
                    ml--;
                }
            }

            // 计算gas使用量
            uint256 newGasLeft = gasleft();
            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed + (gasLeft - newGasLeft);
            }
            gasLeft = newGasLeft;
        }
    }

function setBlockAddress(address _addr, bool _flag) public onlyOwner {
        require(_addr != address(0), "Invalid address");
         blackAddress[_addr] = _flag;
    }

    // 设置买入费用比例
    function setBuyFeePercent(uint256 _buyFeePercent) public onlyOwner {
        buyFeePercent = _buyFeePercent;
    }
  
    // 设置卖出费用比例
    function setSellFeePercent(uint256 _sellFeePercent) public onlyOwner {
        sellFeePercent = _sellFeePercent;
    }
    
    // 设置卖出销毁比例
    function setSellBurnPercent(uint256 _sellBurnPercent) public onlyOwner {
        sellBurnPercent = _sellBurnPercent;
    }
    
    // 设置卖出生态地址费比例
    function setSellEcoFeePercent(uint256 _sellEcoFeePercent) public onlyOwner {
        sellEcoFeePercent = _sellEcoFeePercent;
    }
    
    // 设置卖出Fo池分红费比例
    function setSellFoPoolFeePercent(uint256 _sellFoPoolFeePercent) public onlyOwner {
        sellFoPoolFeePercent = _sellFoPoolFeePercent;
    }
    
    // 设置卖出社区奖励费比例
    function setSellCommunityFeePercent(uint256 _sellCommunityFeePercent) public onlyOwner {
        sellCommunityFeePercent = _sellCommunityFeePercent;
    }
    
    // 设置卖出进入Mo池比例
    function setSellMoPoolPercent(uint256 _sellMoPoolPercent) public onlyOwner {
        sellMoPoolPercent = _sellMoPoolPercent;
    }
    
    // 设置持有锁定时间
    function setHoldingTime(uint256 _holdingTime) public onlyOwner {
        holdingTime = _holdingTime;
    }
    
    // 设置利润限制倍数
    function setProfitLimit(uint256 _profitLimit) public onlyOwner {
        profitLimit = _profitLimit;
    }
    
  
    // 设置技术维护地址
    function setTechAddress(address _techAddress) public onlyOwner {
        require(_techAddress != address(0), "Invalid address");
        techAddress = _techAddress;
    }
    
    // 设置生态地址
    function setEcoAddress(address _ecoAddress) public onlyOwner {
        require(_ecoAddress != address(0), "Invalid address");
        ecoAddress = _ecoAddress;
    }
    
    // 设置Fo池分红地址
    function setFoPoolRewardAddress(address _foPoolRewardAddress) public onlyOwner {
        require(_foPoolRewardAddress != address(0), "Invalid address");
        foPoolRewardAddress = _foPoolRewardAddress;
    }
    
    // 设置社区奖励地址
    function setCommunityRewardAddress(address _communityRewardAddress) public onlyOwner {
        require(_communityRewardAddress != address(0), "Invalid address");
        communityRewardAddress = _communityRewardAddress;
    }

    function setGasLimit(uint256 _gasLimit) public onlyOwner {
        gasLimit = _gasLimit;
    }
     // 设置社区长分红比例
    function setCommunityLeaderFeePercent(uint256 _percent) public onlyOwner {
         sellCommunityLeaderFeePercent = _percent;
    }
    // 设置池合约地址
    function setPoolContracts(address _foPoolAddress, address _moPoolAddress) public onlyOwner {
        require(_foPoolAddress != address(0) && _moPoolAddress != address(0), "Invalid addresses");
        foPoolContract = IPoolBase(_foPoolAddress);
        moPoolContract = IPoolBase(_moPoolAddress);

    }

    function getReserves() public view returns (uint256, uint256) {
        return (address(this).balance, super.balanceOf(address(this)));
    }

    function setMinDepost(uint256 _minDepost) public onlyOwner {
        minDeposit = _minDepost;
    }
 

    function getAmountOut(uint256 value, bool _buy)
        public
        view
        returns (uint256)
    {
        (uint256 reserveETH, uint256 reserveToken) = getReserves();

        if (_buy) {
            return (value * reserveToken) / (reserveETH + value);
        } else {
            return (value * reserveETH) / (reserveToken + value);
        }
    }

   

    receive() external payable {
        deposit();
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

    function swapBNBToUSDT(uint256 bnbAmount) internal {
        address[] memory path = getPathForBNBtoUSDT();
        router.swapExactETHForTokens{value: bnbAmount}(
            0, // Accept any amount of USDT
            path,
            address(this),
            block.timestamp
        );
    }

    // Get the path for swapping BNB to USDT
    function getPathForBNBtoUSDT() public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = usdtAddress;
        return path;
    }
}
