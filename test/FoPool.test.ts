import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { BaseContract, Contract } from "ethers";
import { MockERC20__factory } from "../typechain-types/factories/contracts/mocks";
import { MockERC20, MockFoMox } from "../typechain-types/contracts/mocks";
import { v2Core } from "../typechain-types/@uniswap";
import { v2Periphery } from "../typechain-types/factories/@uniswap";
import { IUniswapV2Router02 } from "../typechain-types/@uniswap/v2-periphery/contracts/interfaces";
import { FoPool, IUniswapV2Pair } from "../typechain-types";
import { MockUniswapV2Pair, MockUniswapV2PairInterface } from "../typechain-types/contracts/mocks/MockUniswapV2Pair";
import { MockUniswapV2Router02, MockUniswapV2Router02Interface } from "../typechain-types/contracts/mocks/MockUniswapV2Router02";

describe("FoPool", function () {
  // 合约实例
  let foPool: FoPool;
  let mockFoMox: MockFoMox;
  let mockUSDT: MockERC20;
  let mockRouter: MockUniswapV2Router02;
  let mockPair: MockUniswapV2Pair;
  
  // 签名者
  let owner: any;
  let user1: any;
  let user2: any;
  let user3: any;

  // 签名者地址
  let ownerAddress: string;
  let user1Address: string;
  let user2Address: string;
  let user3Address: string;
  
  // 常量
  const INITIAL_USDT_SUPPLY = ethers.parseEther("1000000");
  const MIN_DEPOSIT = ethers.parseEther("50");
  const MAX_DEPOSIT = ethers.parseEther("100");
  const ETH_DEPOSIT_AMOUNT = ethers.parseEther("1");
  const USDT_AMOUNT_AFTER_SWAP = ethers.parseEther("100");
  
  beforeEach(async function () {
    // 获取签名者
    [owner, user1, user2, user3] = await ethers.getSigners();
    ownerAddress = await owner.getAddress();
    user1Address = await user1.getAddress();
    user2Address = await user2.getAddress();
    user3Address = await user3.getAddress();

    // 部署模拟合约
    const MockERC20 = await ethers.getContractFactory("MockERC20") as MockERC20__factory;
    mockUSDT = await MockERC20.deploy("Mock USDT", "USDT", INITIAL_USDT_SUPPLY);

    // 部署模拟RouterV2
    const MockRouter = await ethers.getContractFactory("MockUniswapV2Router02");
    mockRouter = (await MockRouter.deploy(mockUSDT.target)) as MockUniswapV2Router02;

        // 部署模拟FoMox
        const MockFoMox = await ethers.getContractFactory("MockFoMox");
        mockFoMox = (await MockFoMox.deploy()) as MockFoMox;
        await mockFoMox.setMaxBuyAmount(MAX_DEPOSIT);
    // 部署模拟交易对
    const MockPair = await ethers.getContractFactory("MockUniswapV2Pair");
    mockPair = (await MockPair.deploy(mockFoMox.target,mockUSDT.target)) as MockUniswapV2Pair;



    // 将USDT转给Router以便模拟兑换
    await mockUSDT.transfer(mockRouter.target, ethers.parseEther("10000"));

    // 部署FoPool
    const FoPool = await ethers.getContractFactory("FoPool")    ;
    foPool = (await upgrades.deployProxy(FoPool, [
      mockFoMox.target,
      mockUSDT.target,
      mockRouter.target,
      mockPair.target
    ]) as unknown) as FoPool;

    // 设置池子配置
    await foPool.setMinDeposit(MIN_DEPOSIT);
    await foPool.setMaxPoolPercent(40);
    
    // 配置模拟行为
    await mockRouter.setSwapExactETHForTokensAmount(USDT_AMOUNT_AFTER_SWAP);
    await mockPair.setReserves(ethers.parseEther("1000000"), ethers.parseEther("100000"));
  });

  describe("初始化", function () {
    it("应该正确初始化合约参数", async function () {
      expect(await foPool.fomoxContract()).to.equal(mockFoMox.target);
      expect(await foPool.usdtContract()).to.equal(mockUSDT.target);
      expect(await foPool.router()).to.equal(mockRouter.target);
      expect(await foPool.uniswapPair()).to.equal(mockPair.target);
      expect(await foPool.minDeposit()).to.equal(MIN_DEPOSIT);
      expect(await foPool.maxPoolPercent()).to.equal(40);
    });
  });

  describe("存款功能", function () {
    it("应该允许用户存入ETH", async function () {
        console.log("calculateMaxBuyAmount",await mockFoMox.calculateMaxBuyAmount());
      // 存入ETH
      await foPool.connect(user1).depositToFoPool({ value: ETH_DEPOSIT_AMOUNT });
      
      // 验证用户存款金额
      expect(await foPool.getUserAmount(user1Address)).to.equal(USDT_AMOUNT_AFTER_SWAP);
      
      // 验证总存款金额
      expect(await foPool.getTotalAmount()).to.equal(USDT_AMOUNT_AFTER_SWAP);
      
      // 验证池子长度
      expect(await foPool.getPoolLength()).to.equal(1);
      
      // 获取并验证池子内容
      const pool = await foPool.getPoolAt();
      expect(pool.addr).to.equal(user1Address);
      expect(pool.usdtAmount).to.equal(USDT_AMOUNT_AFTER_SWAP);
      expect(pool.bnbAmount).to.equal(ETH_DEPOSIT_AMOUNT);
    });

    it("不应该允许用户存入低于最小存款的ETH", async function () {
      // 设置模拟Router返回非常小的USDT金额
      await mockRouter.setSwapExactETHForTokensAmount(ethers.parseEther("10"));
      
      // 存入ETH应该失败
      await expect(
        foPool.connect(user1).depositToFoPool({ value: ETH_DEPOSIT_AMOUNT })
      ).to.be.revertedWith("Deposit amount too small");
    });

    it("不应该允许已存款的用户再次存款", async function () {
      // 先存入一次
      await foPool.connect(user1).depositToFoPool({ value: ETH_DEPOSIT_AMOUNT });
      
      // 再次存入应该失败
      await expect(
        foPool.connect(user1).depositToFoPool({ value: ETH_DEPOSIT_AMOUNT })
      ).to.be.revertedWith("Already deposited in Fo pool");
    });

    it("不应该允许存款超过流动性上限", async function () {
      // 设置模拟池返回较小的流动性
      await mockPair.setReserves(ethers.parseEther("100"), ethers.parseEther("10"));
      
      // 存入应该失败
      await expect(
        foPool.connect(user1).depositToFoPool({ value: ETH_DEPOSIT_AMOUNT })
      ).to.be.revertedWith("Fo pool exceeded 40% of liquidity");
    });
  });

  describe("处理订单功能", function () {
    beforeEach(async function () {
      // 先存入ETH
      await foPool.connect(user1).depositToFoPool({ value: ETH_DEPOSIT_AMOUNT });
      
      // 转USDT到FoPool合约，以便处理订单
      await mockUSDT.transfer(foPool.target, USDT_AMOUNT_AFTER_SWAP);
    });

    it("应该允许FoMox处理订单", async function () {
      // 从模拟FoMox调用处理订单
      await mockFoMox.mockProcessOrder(foPool.target, mockFoMox.target);
      
      // 验证处理计数增加
      expect(await foPool.getProcessCount()).to.equal(1);
    });

    it("应该允许FoMox清除用户存款", async function () {
      // 从模拟FoMox调用清除用户存款
      await mockFoMox.mockClearUserDeposit(foPool.target, user1Address);
      
      // 验证用户存款被清除
      expect(await foPool.getUserAmount(user1Address)).to.equal(0);
    });

    it("应该允许FoMox移除订单", async function () {
      // 从模拟FoMox调用移除订单
      await mockFoMox.mockRemoveOrder(foPool.target);
      
      // 验证总金额减少
      expect(await foPool.getTotalAmount()).to.equal(0);
    });

    it("非FoMox地址不应该能处理订单", async function () {
      // 从普通用户调用处理订单
      await expect(
        foPool.connect(user2).processOrder(user2Address)
      ).to.be.revertedWith("Only FoMox can call");
    });
  });

  describe("设置功能", function () {
    it("应该允许所有者设置最小存款额", async function () {
      const newMinDeposit = ethers.parseEther("100");
      await foPool.setMinDeposit(newMinDeposit);
      expect(await foPool.minDeposit()).to.equal(newMinDeposit);
    });

    it("应该允许所有者设置最大池子百分比", async function () {
      const newMaxPoolPercent = 60;
      await foPool.setMaxPoolPercent(newMaxPoolPercent);
      expect(await foPool.maxPoolPercent()).to.equal(newMaxPoolPercent);
    });

    it("非所有者不应该能设置参数", async function () {
      await expect(
        foPool.connect(user1).setMinDeposit(ethers.parseEther("100"))
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
