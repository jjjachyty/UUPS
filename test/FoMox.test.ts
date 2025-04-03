import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { Contract } from "ethers";
import { FoMox, MockERC20,MockUniswapV2Factory } from "../typechain-types";

describe("FoMox", function () {
  // 合约实例
  let fomox: FoMox;
  let mockUSDT: MockERC20;
  let mockRouter: Contract;
  let mockPair: Contract;
  let mockFoPool: Contract;
  let mockMoPool: Contract;
  let mockFToken: Contract;
  let mockFactory: MockUniswapV2Factory;
  
  // 签名者
  let owner: any;
  let user1: any;
  let user2: any;
  let tech: any;
  let eco: any;
  let foPoolReward: any;
  let communityReward: any;
  
  // 签名者地址
  let ownerAddress: string;
  let user1Address: string;
  let user2Address: string;
  let techAddress: string;
  let ecoAddress: string;
  let foPoolRewardAddress: string;
  let communityRewardAddress: string;
  
  // 常量
  const INITIAL_USDT_SUPPLY = ethers.parseEther("100000000");
  const INITIAL_LIQUIDITY = ethers.parseEther("100000000");
  const INITIAL_USDT = ethers.parseEther("10000");
  const BUY_AMOUNT = ethers.parseEther("100");
  const SELL_AMOUNT = ethers.parseEther("50");
  
  beforeEach(async function () {
    // 获取签名者
    [owner, user1, user2, tech, eco, foPoolReward, communityReward] = await ethers.getSigners();
    ownerAddress = await owner.getAddress();
    user1Address = await user1.getAddress();
    user2Address = await user2.getAddress();
    techAddress = await tech.getAddress();
    ecoAddress = await eco.getAddress();
    foPoolRewardAddress = await foPoolReward.getAddress();
    communityRewardAddress = await communityReward.getAddress();
    
    // 部署模拟USDT
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockUSDT = await MockERC20.deploy("Mock USDT", "USDT", INITIAL_USDT_SUPPLY);
    const MockUniswapV2Factory = await ethers.getContractFactory("MockUniswapV2Factory");
    mockFactory = (await MockUniswapV2Factory.deploy()) as unknown as MockUniswapV2Factory;
    
    // 部署模拟Router
    const MockRouter = await ethers.getContractFactory("MockUniswapV2Router02");
    mockRouter = (await MockRouter.deploy(mockUSDT.target,mockFactory.target)) as unknown as Contract;
    
   
    // 部署模拟Pool合约
    const MockPool = await ethers.getContractFactory("MockPoolBase");
    mockFoPool = (await MockPool.deploy()) as unknown as Contract;
    mockMoPool = (await MockPool.deploy()) as unknown as Contract;
    
    // 部署模拟FToken
    const MockFToken = await ethers.getContractFactory("MockFToken");
    mockFToken = (await MockFToken.deploy()) as unknown as Contract;
    
    // 部署FoMox合约
    const FoMox = await ethers.getContractFactory("FoMox");
    fomox = (await upgrades.deployProxy(FoMox, [
        mockUSDT.target,
        mockRouter.target,
        techAddress,
        ecoAddress,
        foPoolRewardAddress,
        communityRewardAddress,
        mockFoPool.target,
        mockMoPool.target,
        mockFToken.target
    ])) as unknown as FoMox;
     // 部署模拟Pair
     const MockPair = await ethers.getContractFactory("MockUniswapV2Pair");
     mockPair = (await MockPair.deploy(fomox.target, mockUSDT.target)) as unknown as Contract;
     
    
     
     
     await fomox.setUniswapPairAddress(mockPair.target);

    // 设置模拟行为
    await mockRouter.setFactory(mockFactory.target);
    await mockRouter.setPair(mockPair.target);
    await mockPair.setReserves(ethers.parseEther("100000000"), ethers.parseEther("10000"));
    // await mockUSDT.transfer(mockRouter.target, ethers.parseEther("100000"));
    // await mockUSDT.transfer(fomox.target, ethers.parseEther("10000"));
    
    // 设置FoMox地址到池合约
    await mockFoPool.setFomoxAddress(fomox.target);
    await mockMoPool.setFomoxAddress(fomox.target);
    await mockFToken.setFomoxAddress(fomox.target);
  });
  
  describe("初始化", function () {
    it("应该正确初始化合约参数", async function () {
      expect(await fomox.name()).to.equal("FoMox");
      expect(await fomox.symbol()).to.equal("FOMOX");
      expect(await fomox.usdtAddress()).to.equal(mockUSDT.target);
      expect(await fomox.router()).to.equal(mockRouter.target);
      expect(await fomox.techAddress()).to.equal(techAddress);
      expect(await fomox.ecoAddress()).to.equal(ecoAddress);
      expect(await fomox.foPoolRewardAddress()).to.equal(foPoolRewardAddress);
      expect(await fomox.communityRewardAddress()).to.equal(communityRewardAddress);
      expect(await fomox.foPoolContract()).to.equal(mockFoPool.target);
      expect(await fomox.moPoolContract()).to.equal(mockMoPool.target);
      expect(await fomox.fTokenContract()).to.equal(mockFToken.target);
    });
    
    it("应该设置初始价格", async function () {
      const expectedInitialPrice = INITIAL_USDT * (10n**18n) / INITIAL_LIQUIDITY;
      expect(await fomox.todayStartPrice()).to.equal(expectedInitialPrice);
    });
    
    it("应该设置默认参数", async function () {
      expect(await fomox.buyFeePercent()).to.equal(7);
      expect(await fomox.sellFeePercent()).to.equal(8);
      expect(await fomox.profitLimit()).to.equal(2);
      expect(await fomox.holdingTime()).to.equal(72 * 3600); // 72小时
    });
  });
  
  describe("价格控制", function () {
    it("应该正确获取当前价格", async function () {
      // 获取当前价格
      const currentPrice = await fomox.getCurrentPrice();
      // 由于模拟的Pair设置储备为1000000 USDT和100000 Token
      const expectedPrice = ethers.parseEther("0.0001"); // 10 USDT per Token
      expect(currentPrice).to.equal(expectedPrice);
    });
    
    it("应该根据流动性获取正确的价格控制参数", async function () {
      // 获取当前价格控制参数
      const [maxIncreasePct, triggerPct] = await fomox.getCurrentPriceControlParams(ethers.parseEther("50000"));
      // 应该返回第二个层级的参数
      expect(maxIncreasePct).to.equal(20); // 15% max daily increase
      expect(triggerPct).to.equal(10); // 10% trigger decrease
    });
    
    it("应该检查价格是否超过日涨幅", async function () {
      // 初始设置，价格应在限制内
      expect(await fomox.checkDailyPriceLimit()).to.be.true;
      
      // 修改价格使其超过限制
      await mockPair.setReserves(ethers.parseEther("10000000"), ethers.parseEther("100000")); // 价格为100，远超限制
      expect(await fomox.checkDailyPriceLimit()).to.be.false;
    });
  });
  
  describe("最大买入计算", function () {
    it("应该根据流动性计算最大买入金额", async function () {
      // 测试不同流动性下的最大买入金额
      await mockPair.setReserves(ethers.parseEther("20000"), ethers.parseEther("20000")); // 2万USDT流动性
      expect(await fomox.calculateMaxBuyAmount()).to.equal(ethers.parseEther("100"));
      
      await mockPair.setReserves(ethers.parseEther("40000"), ethers.parseEther("40000")); // 4万USDT流动性
      expect(await fomox.calculateMaxBuyAmount()).to.equal(ethers.parseEther("200"));
      
      await mockPair.setReserves(ethers.parseEther("200000"), ethers.parseEther("200000")); // 20万USDT流动性
      expect(await fomox.calculateMaxBuyAmount()).to.equal(ethers.parseEther("1000"));
    });
  });
  
  describe("管理员功能", function () {
    it("应该允许所有者设置参数", async function () {
      await fomox.setBuyFeePercent(5);
      expect(await fomox.buyFeePercent()).to.equal(5);
      
      await fomox.setSellFeePercent(10);
      expect(await fomox.sellFeePercent()).to.equal(10);
      
      await fomox.setHoldingTime(48 * 3600); // 48小时
      expect(await fomox.holdingTime()).to.equal(48 * 3600);
    });
    
    it("非所有者不应该能设置参数", async function () {
      await expect(
        fomox.connect(user1).setBuyFeePercent(5)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
    
    it("应该允许所有者设置FoMox地址", async function () {
      const newFoMoxAddress = user1Address;
      await fomox.setTechAddress(newFoMoxAddress);
      expect(await fomox.techAddress()).to.equal(newFoMoxAddress);
    });
    
    it("应该允许所有者设置新价格", async function () {
      await fomox.setTodayStartPrice();
      const currentPrice = await fomox.getCurrentPrice();
      expect(await fomox.todayStartPrice()).to.equal(currentPrice);
    });
  });
  
  describe("自动买入执行", function () {
    beforeEach(async function () {
      // 准备自动买入测试环境
      await mockFoPool.setTotalAmount(ethers.parseEther("1000"));
      await mockMoPool.setTotalAmount(ethers.parseEther("500"));
      await mockFoPool.setPoolLength(3);
      await mockMoPool.setPoolLength(2);
    });
    
    it("应该能执行自动买入", async function () {
      // 设置价格跌破触发点
     
      
      await mockPair.setReserves(ethers.parseEther("100000"), ethers.parseEther("9000")); // 降低价格到0.9
      await fomox.setTodayStartPrice();
      const originalPrice = await fomox.todayStartPrice();
      console.log("Original Price:", originalPrice.toString());
      // 执行自动买入
      await fomox.executeAutoBuy(false);
      
      // 验证Fo池和Mo池处理计数
      // 这里依赖于模拟合约的实现，假设它们会跟踪相关调用
      expect(await mockFoPool.getProcessedCount()).to.be.greaterThan(0);
      expect(await mockMoPool.getProcessedCount()).to.be.greaterThan(0);
    });
    
    it("价格高于停止价格时不应执行买入", async function () {
      // 设置价格高于触发点
      await mockPair.setReserves(ethers.parseEther("110000"), ethers.parseEther("100000")); // 提高价格到1.1
      
      // 执行自动买入
      await fomox.executeAutoBuy(false);
      
      // 验证没有处理任何订单
      expect(await mockFoPool.getProcessedCount()).to.equal(0);
      expect(await mockMoPool.getProcessedCount()).to.equal(0);
    });
  });
  
  describe("兑换计算", function () {
    it("应该正确计算Token到USDT的兑换量", async function () {
      // 设置模拟Router的兑换比率
      const tokenAmount = ethers.parseEther("100");
      const expectedUsdtAmount = ethers.parseEther("1000"); // 假设1 Token = 10 USDT
      
      // 在Router中设置这个比率
      await mockRouter.setTokenToUsdtRate(tokenAmount, expectedUsdtAmount);
      
      // 调用合约函数
      const result = await fomox.getTokenToUSDTAmount(fomox.target, mockUSDT.target, tokenAmount);
      expect(result).to.equal(expectedUsdtAmount);
    });
    
    it("应该正确计算USDT到Token的兑换量", async function () {
      // 设置模拟Router的兑换比率
      const usdtAmount = ethers.parseEther("1000");
      const expectedTokenAmount = ethers.parseEther("100"); // 假设10 USDT = 1 Token
      
      // 在Router中设置这个比率
      await mockRouter.setUsdtToTokenRate( expectedTokenAmount,usdtAmount);
      
      // 调用合约函数
      const result = await fomox.getUSDTToTokenAmount(mockUSDT.target, fomox.target, usdtAmount);
      expect(result).to.equal(expectedTokenAmount);
    });
  });
});
