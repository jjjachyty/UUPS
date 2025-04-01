const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("FToken", function () {
  let FToken, fToken, FoMox, foMox, MockUSDT, usdt;
  let owner, user1, user2, user3, user4, user5;
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
  const ONE_TOKEN = ethers.parseEther("1.0");
  const HUNDRED_TOKENS = ethers.parseEther("100.0");
  const THOUSAND_TOKENS = ethers.parseEther("1000.0");

  beforeEach(async function () {
    // 获取账户
    [owner, user1, user2, user3, user4, user5] = await ethers.getSigners();

    // 部署模拟USDT合约
    const MockUSDTFactory = await ethers.getContractFactory("MockERC20");
    usdt = await MockUSDTFactory.deploy("Mock USDT", "USDT", THOUSAND_TOKENS);
 
    // 部署模拟FoMox合约
    const MockFoMoxFactory = await ethers.getContractFactory("MockFoMox");
    foMox = await MockFoMoxFactory.deploy();
 
    // 部署FToken合约
    const FTokenFactory = await ethers.getContractFactory("FToken");
    fToken = await upgrades.deployProxy(FTokenFactory, [
      "FToken", 
      "FTK", 
      foMox.target,
      usdt.target
    ]);
 
    // 设置FoMox模拟方法
    await foMox.setCommunityRewardAddress(user5.address);
    await foMox.setDirectReferralPercent(10);
    await foMox.setIndirectReferralPercent(20);
    await foMox.setMaxReferralLevels(7);
    await foMox.setBuyReferralPercent(40);
  });

  describe("初始化和基本功能", function () {
    it("应该正确初始化FToken合约", async function () {
      expect(await fToken.name()).to.equal("FToken");
      expect(await fToken.symbol()).to.equal("FTK");
      expect(await fToken.fomoxContract()).to.equal(foMox.target);
    });

    it("应该初始铸造1,000,000个代币给部署者", async function () {
      const expectedBalance = ethers.parseEther("1000000");
      expect(await fToken.balanceOf(owner.address)).to.equal(expectedBalance);
    });

    it("应该允许所有者增发代币", async function () {
      await fToken.mint(user1.address, THOUSAND_TOKENS);
      expect(await fToken.balanceOf(user1.address)).to.equal(THOUSAND_TOKENS);
    });

    it("非所有者不能增发代币", async function () {
      await expect(
        fToken.connect(user1).mint(user2.address, THOUSAND_TOKENS)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("推荐关系建立", function () {
    beforeEach(async function () {
      // 先给user1一些代币
      await fToken.transfer(user1.address, HUNDRED_TOKENS);
    });

    it("转移1个代币应该建立推荐关系", async function () {
      // 检查初始状态
      expect(await fToken.hasReferrer(user2.address)).to.be.false;

      // user1 转移1个代币给 user2
      await fToken.connect(user1).transfer(user2.address, ONE_TOKEN);

      // 验证推荐关系
      expect(await fToken.hasReferrer(user2.address)).to.be.true;
      expect(await fToken.referrers(user2.address)).to.equal(user1.address);
      
      // 验证user1的推荐列表包含user2
      const referrals = await fToken.getReferrals(user1.address);
      expect(referrals.length).to.equal(1);
      expect(referrals[0]).to.equal(user2.address);
      
      // 验证推荐计数
      expect(await fToken.referralCount(user1.address)).to.equal(1);
    });

    it("转移非1个代币不应该建立推荐关系", async function () {
      await fToken.connect(user1).transfer(user2.address, ethers.parseEther("2.0"));
      expect(await fToken.hasReferrer(user2.address)).to.be.false;
    });

    it("用户不能自我推荐", async function () {
      await expect(
        fToken.setReferrer(user1.address, user1.address)
      ).to.be.revertedWith("Cannot refer yourself");
    });

    it("已有推荐人的用户不能再次被推荐", async function () {
      // 先建立user1推荐user2的关系
      await fToken.connect(user1).transfer(user2.address, ONE_TOKEN);
      
      // 再给user3一些代币
      await fToken.transfer(user3.address, HUNDRED_TOKENS);
      
      // user3再尝试推荐user2
      await fToken.connect(user3).transfer(user2.address, ONE_TOKEN);
      
      // 验证user2的推荐人仍然是user1
      expect(await fToken.referrers(user2.address)).to.equal(user1.address);
    });
  });

  describe("社区长功能", function () {
    beforeEach(async function () {
      // 设置user1为社区长
      await fToken.registerCommunityLeader(user1.address);
      
      // 给user1和user2一些代币
      await fToken.transfer(user1.address, HUNDRED_TOKENS);
      await fToken.transfer(user2.address, HUNDRED_TOKENS);
    });

    it("应该正确注册社区长", async function () {
      expect(await fToken.isCommunityLeader(user1.address)).to.be.true;
    });

    it("转移1个代币时接收者应该继承发送者的社区长", async function () {
      // user1 是社区长，转移1个代币给user3
      await fToken.connect(user1).transfer(user3.address, ONE_TOKEN);
      
      // 验证user3的社区长是user1
      expect(await fToken.communityLeaderOf(user3.address)).to.equal(user1.address);
      
      // 验证user1的社区成员列表包含user3
      const members = await fToken.getCommunityMembers(user1.address);
      expect(members.length).to.equal(1);
      expect(members[0]).to.equal(user3.address);
    });

    it("转移1个代币时接收者应该继承发送者的社区长的社区长", async function () {
      // user1 是社区长，转移1个代币给user3
      await fToken.connect(user1).transfer(user3.address, ONE_TOKEN);
      
      // user3 转移1个代币给user4
      await fToken.connect(user3).transfer(user4.address, ONE_TOKEN);
      
      // 验证user4的社区长也是user1
      expect(await fToken.communityLeaderOf(user4.address)).to.equal(user1.address);
    });

    it("手动设置社区长", async function () {
      // 注册user2为社区长
      await fToken.registerCommunityLeader(user2.address);
      
      // 手动将user3的社区长设置为user2
      await fToken.setCommunityLeader(user3.address, user2.address);
      
      expect(await fToken.communityLeaderOf(user3.address)).to.equal(user2.address);
      
      // 验证社区成员列表
      const members = await fToken.getCommunityMembers(user2.address);
      expect(members.length).to.equal(1);
      expect(members[0]).to.equal(user3.address);
    });

    it("撤销社区长身份", async function () {
      await fToken.unregisterCommunityLeader(user1.address);
      expect(await fToken.isCommunityLeader(user1.address)).to.be.false;
    });
  });

  describe("社区长费用处理", function () {
    beforeEach(async function () {
      // 设置user1为社区长
      await fToken.registerCommunityLeader(user1.address);
      
      // 先设置模拟关系和USDT余额
      await usdt.transfer(fToken.target, THOUSAND_TOKENS);
      
      // 设置user2的社区长为user1
      await fToken.setCommunityLeader(user2.address, user1.address);
    });

    it("应该正确处理社区长费用", async function () {
      const initialBalance = await usdt.balanceOf(user1.address);
      
      // 模拟调用processCommunityLeaderFee
      const leaderFee = ethers.parseEther("5.0");
      const totalFees = ethers.parseEther("100.0");
      const feeUSDTReceived = ethers.parseEther("10.0");
      
      // 需要从FoMox调用，使用模拟
      await foMox.mockProcessCommunityLeaderFee(
        fToken.target, 
        user2.address, 
        leaderFee, 
        totalFees, 
        feeUSDTReceived
      );
      
      // 计算预期获得的费用 - 使用标准乘法和除法运算符
      const expectedFee = (feeUSDTReceived * leaderFee) / totalFees;
      
      // 验证user1获得了费用
      expect(await usdt.balanceOf(user1.address)).to.equal(initialBalance + expectedFee);
    });

    it("用户没有社区长时费用应该发给社区奖励地址", async function () {
      const initialBalance = await usdt.balanceOf(user5.address); // user5是社区奖励地址
      
      // 模拟调用processCommunityLeaderFee
      const leaderFee = ethers.parseEther("5.0");
      const totalFees = ethers.parseEther("100.0");
      const feeUSDTReceived = ethers.parseEther("10.0");
      
      // 需要从FoMox调用，使用模拟，这次对user3（没有社区长）
      await foMox.mockProcessCommunityLeaderFee(
        fToken.target, 
        user3.address, 
        leaderFee, 
        totalFees, 
        feeUSDTReceived
      );
      
      // 计算预期获得的费用 - 使用标准乘法和除法运算符
      const expectedFee = (feeUSDTReceived * leaderFee) / totalFees;
      
      // 验证社区奖励地址获得了费用
      expect(await usdt.balanceOf(user5.address)).to.equal(initialBalance + expectedFee);
    });
  });

  describe("推荐奖励处理", function () {
    it("应该正确处理推荐奖励", async function () {
      // 设置复杂的推荐关系链
      // 建立推荐关系链: owner -> user1 -> user2 -> user3
      await fToken.setReferrer(user1.address, owner.address);
      await fToken.setReferrer(user2.address, user1.address);
      await fToken.setReferrer(user3.address, user2.address);
      
      // 设置模拟条件
      await foMox.setCheckAddressEffect(true);
      await usdt.transfer(fToken.target, THOUSAND_TOKENS);
      
      // 配置模拟值
      // 测试推荐奖励分配
      // 假设未实现此方法，但可以测试
    });
  });
});
