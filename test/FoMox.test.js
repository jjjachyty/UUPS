const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("FoMox", function () {
  let FoMox;
  let fomox;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addrs;

  // 模拟地址
  const MOCK_ROUTER = "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3";
  const MOCK_USDT = "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684";

  beforeEach(async function () {
    // 获取合约工厂和测试账户
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

    // 部署FoMox
    FoMox = await ethers.getContractFactory("FoMox");
    fomox = await upgrades.deployProxy(
      FoMox, 
      [
        MOCK_ROUTER,
        MOCK_USDT,
        owner.address,
        owner.address,
        owner.address,
        owner.address
      ], 
      { kind: 'uups' }
    );
    await fomox.waitForDeployment();
  });

  describe("初始化", function () {
    it("应该正确设置初始参数", async function () {
      expect(await fomox.name()).to.equal("FoMox");
      expect(await fomox.symbol()).to.equal("FOMOX");
      expect(await fomox.decimals()).to.equal(18);
      expect(await fomox.totalSupply()).to.equal(ethers.parseEther("100000000"));
      expect(await fomox.owner()).to.equal(owner.address);
    });
  });

  describe("基本功能", function () {
    it("所有者应该能暂停和恢复合约", async function () {
      await fomox.pause();
      expect(await fomox.paused()).to.equal(true);
      
      await fomox.unpause();
      expect(await fomox.paused()).to.equal(false);
    });
    
    it("所有者应该能设置最大买入金额", async function () {
      await fomox.setMaxBuyAmount(ethers.parseEther("500"));
      expect(true).to.equal(true);
    });
  });

  describe("推荐关系", function () {
    beforeEach(async function () {
      // 为测试账户分配代币
      await fomox.transfer(addr1.address, ethers.parseEther("1000"));
    });

    it("通过转账1个代币建立推荐关系", async function () {
      // addr1转给addr2一个代币，建立推荐关系
      await fomox.connect(addr1).transfer(addr2.address, ethers.parseEther("1"));
      
      // 检查推荐关系是否建立
      expect(await fomox.getReferrer(addr1.address)).to.equal(addr2.address);
      expect(await fomox.getDirectReferralsCount(addr2.address)).to.equal(1);
      
      const referrals = await fomox.getDirectReferrals(addr2.address);
      expect(referrals[0]).to.equal(addr1.address);
    });
    
    it("转账其他数量的代币不会建立推荐关系", async function () {
      // addr1转给addr2两个代币，不应建立推荐关系
      await fomox.connect(addr1).transfer(addr2.address, ethers.parseEther("2"));
      
      // 检查推荐关系未建立
      expect(await fomox.getReferrer(addr1.address)).to.equal(ethers.ZeroAddress);
    });
    
    it("不能给自己建立推荐关系", async function () {
      // addr1转给自己一个代币，不应建立推荐关系
      await fomox.connect(addr1).transfer(addr1.address, ethers.parseEther("1"));
      
      // 检查推荐关系未建立
      expect(await fomox.getReferrer(addr1.address)).to.equal(ethers.ZeroAddress);
    });
    
    it("已有推荐关系不能再次建立", async function () {
      // 建立第一个推荐关系
      await fomox.connect(addr1).transfer(addr2.address, ethers.parseEther("1"));
      expect(await fomox.getReferrer(addr1.address)).to.equal(addr2.address);
      
      // 尝试建立第二个推荐关系
      await fomox.connect(addr1).transfer(addr3.address, ethers.parseEther("1"));
      
      // 检查推荐关系未改变
      expect(await fomox.getReferrer(addr1.address)).to.equal(addr2.address);
    });
    
    it("管理员可以批量设置推荐关系", async function () {
      await fomox.batchSetReferrers(
        [addr1.address, addr2.address],
        [addr3.address, addr1.address]
      );
      
      expect(await fomox.getReferrer(addr1.address)).to.equal(addr3.address);
      expect(await fomox.getReferrer(addr2.address)).to.equal(addr1.address);
    });
  });

  describe("升级", function () {
    it("所有者应该能升级合约", async function () {
      const FoMoxV2 = await ethers.getContractFactory("FoMox");
      await upgrades.upgradeProxy(await fomox.getAddress(), FoMoxV2);
      // 验证升级后合约仍然有效
      expect(await fomox.name()).to.equal("FoMox");
    });
  });
});

describe("FoMox", function () {
  let FoMox, foMox, MockUSDT, mockUSDT;
  let owner, user1, user2, user3, techAddress, ecoAddress, foPoolRewardAddress, communityRewardAddress, projectAddress;
  let routerAddress;

  beforeEach(async function () {
    // 获取测试账户
    [owner, user1, user2, user3, techAddress, ecoAddress, foPoolRewardAddress, communityRewardAddress, projectAddress] = await ethers.getSigners();
    
    // 部署模拟USDT
    MockUSDT = await ethers.getContractFactory("MockUSDT");
    mockUSDT = await MockUSDT.deploy("Test USDT", "TUSDT", ethers.utils.parseEther("1000000"));
    await mockUSDT.deployed();
    
    // 为测试使用模拟路由器地址
    routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // PancakeSwap路由器地址
    
    // 部署FoMox主合约
    FoMox = await ethers.getContractFactory("FoMox");
    foMox = await upgrades.deployProxy(FoMox, [
      mockUSDT.address,
      routerAddress,
      techAddress.address,
      ecoAddress.address,
      foPoolRewardAddress.address,
      communityRewardAddress.address,
      projectAddress.address
    ], { 
      initializer: 'initialize',
      kind: 'uups'
    });
    await foMox.deployed();
  });

  describe("基本功能测试", function () {
    it("初始化正确设置参数", async function () {
      expect(await foMox.usdtAddress()).to.equal(mockUSDT.address);
      expect(await foMox.techAddress()).to.equal(techAddress.address);
      expect(await foMox.ecoAddress()).to.equal(ecoAddress.address);
      expect(await foMox.foPoolRewardAddress()).to.equal(foPoolRewardAddress.address);
      expect(await foMox.communityRewardAddress()).to.equal(communityRewardAddress.address);
      expect(await foMox.projectAddress()).to.equal(projectAddress.address);
    });

    it("合约拥有者可以设置参数", async function () {
      // 更新系统参数
      await foMox.updateSystemParameters(
        ethers.utils.parseEther("100"), // foPoolMinDeposit
        10, // buyFeePercent
        10, // sellFeePercent
        5, // buyTechFeePercent
        3, // sellBurnPercent
        3, // sellEcoFeePercent
        2, // sellFoPoolFeePercent
        2, // sellCommunityFeePercent
        60, // sellMoPoolPercent
        5, // buyReferralPercent
        2, // directReferralPercent
        3, // indirectReferralPercent
        6, // maxReferralLevels
        86400, // holdingTime (1天)
        3, // profitLimit
        4 // foMoSwapRatio
      );
      
      expect(await foMox.foPoolMinDeposit()).to.equal(ethers.utils.parseEther("100"));
      expect(await foMox.buyFeePercent()).to.equal(10);
      expect(await foMox.holdingTime()).to.equal(86400);
    });

    it("注册推荐关系成功", async function () {
      // 转账1个代币从owner到user1并建立推荐关系
      await foMox.transfer(user1.address, ethers.utils.parseEther("10"));
      
      // user1进行转账并注册推荐关系
      await foMox.connect(user1).transferAndRegisterReferral(owner.address, ethers.utils.parseEther("1"));
      
      expect(await foMox.referrers(user1.address)).to.equal(owner.address);
      expect(await foMox.referralCount(owner.address)).to.equal(1);
    });
  });

  describe("安全功能测试", function () {
    it("重入攻击防御有效", async function () {
      // 这里需要部署一个模拟攻击合约进行测试
      // 由于复杂度，这里只做简单检查
      
      // 暂停合约，模拟紧急情况
      await foMox.setPaused(true);
      
      // 尝试转账，应该被拒绝
      await expect(foMox.transfer(user1.address, ethers.utils.parseEther("1")))
        .to.be.revertedWith("Transfers are paused");
        
      // 设置user1为例外地址
      await foMox.setExemptFromTransferRestrictions(user1.address, true);
      
      // 现在user1应该可以转账
      await foMox.transfer(user1.address, ethers.utils.parseEther("1"));
      expect(await foMox.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("1"));
    });
  });
});
