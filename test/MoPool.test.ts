import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { Contract } from "ethers";
import { MockERC20, MockFoMox, MockUniswapV2Router02 } from "../typechain-types/contracts/mocks";
import { MoPool } from "../typechain-types";

describe("MoPool", function () {
  // 合约实例
  let moPool: MoPool;
  let mockFoMox: MockFoMox;
  let mockUSDT: MockERC20;
  let mockRouter: MockUniswapV2Router02;
  
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
  const DEPOSIT_AMOUNT = ethers.parseEther("100");
  
  beforeEach(async function () {
    // 获取签名者
    [owner, user1, user2, user3] = await ethers.getSigners();
    ownerAddress = await owner.getAddress();
    user1Address = await user1.getAddress();
    user2Address = await user2.getAddress();
    user3Address = await user3.getAddress();

    // 部署模拟合约
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockUSDT = (await MockERC20.deploy("Mock USDT", "USDT", INITIAL_USDT_SUPPLY)) as MockERC20;

    // 部署模拟RouterV2
    const MockRouter = await ethers.getContractFactory("MockUniswapV2Router02");
    mockRouter = (await MockRouter.deploy(mockUSDT.target)) as MockUniswapV2Router02;

    // 部署模拟FoMox合约
    const MockFoMox = await ethers.getContractFactory("MockFoMox");
    mockFoMox = (await MockFoMox.deploy()) as unknown as MockFoMox;

    // 将USDT转给Router以便模拟兑换
    await mockUSDT.transfer(mockRouter.target, ethers.parseEther("10000"));

    // 部署MoPool
    const MoPool = await ethers.getContractFactory("MoPool");
    moPool = await upgrades.deployProxy(MoPool, [
        mockFoMox.target,
        mockUSDT.target,
        mockRouter.target
    ]) as unknown as  MoPool;

    // 转USDT到MoPool合约，用于测试
    await mockUSDT.transfer(moPool.target, ethers.parseEther("10000"));
  });

  describe("初始化", function () {
    it("应该正确初始化合约参数", async function () {
      expect(await moPool.fomoxAddress()).to.equal(mockFoMox.target);
      expect(await moPool.usdtContract()).to.equal(mockUSDT.target);
      expect(await moPool.router()).to.equal(mockRouter.target);
    });
  });

  describe("存款功能", function () {
    it("应该允许FoMox合约添加存款", async function () {
      // 由于只有FoMox可以调用deposit，通过模拟来测试
      // 先修改FoMox实现这个函数
      await mockFoMox.mockDeposit(moPool.target, user1Address, DEPOSIT_AMOUNT, 0);
      
      // 验证存款状态
      expect(await moPool.getUserAmount(user1Address)).to.equal(DEPOSIT_AMOUNT);
      expect(await moPool.getTotalAmount()).to.equal(DEPOSIT_AMOUNT);
      expect(await moPool.getPoolLength()).to.equal(1);
      
      // 验证池子内容
      const pool = await moPool.getPoolAt();
      expect(pool.addr).to.equal(user1Address);
      expect(pool.usdtAmount).to.equal(DEPOSIT_AMOUNT);
      expect(pool.bnbAmount).to.equal(0);
    });

    it("非FoMox地址不能调用deposit函数", async function () {
      await expect(
        moPool.connect(user1).deposit(user1Address, DEPOSIT_AMOUNT, 0)
      ).to.be.revertedWith("Only FoMox can call");
    });
  });

  describe("订单处理", function () {
    beforeEach(async function () {
      // 添加一个Mo池存款
      await mockFoMox.mockDeposit(moPool.target, user1Address, DEPOSIT_AMOUNT, 0);
    });

    it("应该允许FoMox处理订单", async function () {
      // 模拟FoMox调用processOrder
      await mockFoMox.mockProcessOrder(moPool.target, mockFoMox.target);
      
      // 验证处理计数增加
      expect(await moPool.getProcessCount()).to.equal(1);
    });

    it("应该允许FoMox清除用户存款", async function () {
      // 从模拟FoMox调用清除用户存款
      await mockFoMox.mockClearUserDeposit(moPool.target, user1Address);
      
      // 验证用户存款被清除
      expect(await moPool.getUserAmount(user1Address)).to.equal(0);
    });

    it("应该允许FoMox移除订单", async function () {
      // 从模拟FoMox调用移除订单
      await mockFoMox.mockRemoveOrder(moPool.target);
      
      // 验证总金额减少
      expect(await moPool.getTotalAmount()).to.equal(0);
    });

    it("非FoMox地址不应该能处理订单", async function () {
      // 从普通用户调用处理订单
      await expect(
        moPool.connect(user2).processOrder(user2Address)
      ).to.be.revertedWith("Only FoMox can call");
    });
  });

  describe("多用户存款测试", function() {
    it("应该正确处理多个用户的存款", async function() {
      // 添加多个用户的存款
      await mockFoMox.mockDeposit(moPool.target, user1Address, DEPOSIT_AMOUNT, 0);
      await mockFoMox.mockDeposit(moPool.target, user2Address, DEPOSIT_AMOUNT * 2n, 0);
      await mockFoMox.mockDeposit(moPool.target, user3Address, DEPOSIT_AMOUNT * 3n, 0);
      
      // 验证存款状态
      expect(await moPool.getUserAmount(user1Address)).to.equal(DEPOSIT_AMOUNT);
      expect(await moPool.getUserAmount(user2Address)).to.equal(DEPOSIT_AMOUNT * 2n);
      expect(await moPool.getUserAmount(user3Address)).to.equal(DEPOSIT_AMOUNT * 3n);
      
      // 验证总金额
      const expectedTotal = DEPOSIT_AMOUNT + (DEPOSIT_AMOUNT * 2n) + (DEPOSIT_AMOUNT * 3n);
      expect(await moPool.getTotalAmount()).to.equal(expectedTotal);
      
      // 验证池子长度
      expect(await moPool.getPoolLength()).to.equal(3);
    });

    it("应该按顺序处理多个订单", async function() {
      // 添加多个用户的存款
      await mockFoMox.mockDeposit(moPool.target, user1Address, DEPOSIT_AMOUNT, 0);
      await mockFoMox.mockDeposit(moPool.target, user2Address, DEPOSIT_AMOUNT * 2n, 0);
      
      // 第一次处理订单
      await mockFoMox.mockProcessOrder(moPool.target, mockFoMox.target);
      expect(await moPool.getProcessCount()).to.equal(1);
      
      // 第二次处理订单
      await mockFoMox.mockProcessOrder(moPool.target, mockFoMox.target);
      expect(await moPool.getProcessCount()).to.equal(2);
    });
  });

  describe("设置函数", function () {
    it("应该允许所有者设置FoMox地址", async function () {
      const newFoMoxAddress = user3Address;
      await moPool.setFomoxAddress(newFoMoxAddress);
      expect(await moPool.fomoxAddress()).to.equal(newFoMoxAddress);
    });

    it("非所有者不应该能设置FoMox地址", async function () {
      await expect(
        moPool.connect(user1).setFomoxAddress(user2Address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("不能设置零地址作为FoMox地址", async function () {
      await expect(
        moPool.setFomoxAddress(ethers.ZeroAddress)
      ).to.be.revertedWith("Invalid address");
    });
  });
});
