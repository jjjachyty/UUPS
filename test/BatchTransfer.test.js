const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("FoMox - 批量转USDT功能", function () {
  let FoMox, foMox, MockUSDT, mockUSDT;
  let owner, user1, user2, user3, user4, user5;
  let recipients, amounts;

  beforeEach(async function () {
    // 获取测试账户
    [owner, user1, user2, user3, user4, user5, ...addrs] = await ethers.getSigners();
    
    // 部署测试USDT
    MockUSDT = await ethers.getContractFactory("MockUSDT");
    mockUSDT = await MockUSDT.deploy("Test USDT", "TUSDT", ethers.utils.parseEther("1000000"));
    await mockUSDT.deployed();
    
    // 部署FoMox
    FoMox = await ethers.getContractFactory("FoMox");
    foMox = await upgrades.deployProxy(FoMox, [
      mockUSDT.address,
      owner.address, // 模拟路由器地址
      user1.address,
      user2.address,
      user3.address,
      user4.address,
      user5.address
    ], { 
      initializer: 'initialize',
      kind: 'uups'
    });
    await foMox.deployed();
    
    // 给合约转一些USDT
    await mockUSDT.transfer(foMox.address, ethers.utils.parseEther("10000"));
    
    // 准备测试数据
    recipients = [user1.address, user2.address, user3.address];
    amounts = [
      ethers.utils.parseEther("100"),
      ethers.utils.parseEther("200"),
      ethers.utils.parseEther("300")
    ];
  });

  describe("批量转USDT", function () {
    it("只有管理员可以调用批量转USDT函数", async function () {
      await expect(
        foMox.connect(user1).batchTransferUsdt(recipients, amounts)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
    
    it("输入数组长度必须匹配", async function () {
      const invalidAmounts = [ethers.utils.parseEther("100"), ethers.utils.parseEther("200")];
      
      await expect(
        foMox.batchTransferUsdt(recipients, invalidAmounts)
      ).to.be.revertedWith("Arrays length mismatch");
    });
    
    it("成功批量转USDT到多个地址", async function () {
      const beforeBalance1 = await mockUSDT.balanceOf(user1.address);
      const beforeBalance2 = await mockUSDT.balanceOf(user2.address);
      const beforeBalance3 = await mockUSDT.balanceOf(user3.address);
      
      // 执行批量转账
      await foMox.batchTransferUsdt(recipients, amounts);
      
      // 检查余额变化
      expect(await mockUSDT.balanceOf(user1.address)).to.equal(
        beforeBalance1.add(amounts[0])
      );
      expect(await mockUSDT.balanceOf(user2.address)).to.equal(
        beforeBalance2.add(amounts[1])
      );
      expect(await mockUSDT.balanceOf(user3.address)).to.equal(
        beforeBalance3.add(amounts[2])
      );
    });
    
    it("成功使用相同金额批量转USDT", async function () {
      const amount = ethers.utils.parseEther("50");
      const beforeBalance1 = await mockUSDT.balanceOf(user1.address);
      const beforeBalance2 = await mockUSDT.balanceOf(user2.address);
      
      // 执行批量相同金额转账
      await foMox.batchTransferUsdtSameAmount([user1.address, user2.address], amount);
      
      // 检查余额变化
      expect(await mockUSDT.balanceOf(user1.address)).to.equal(
        beforeBalance1.add(amount)
      );
      expect(await mockUSDT.balanceOf(user2.address)).to.equal(
        beforeBalance2.add(amount)
      );
    });
    
    it("合约余额不足时应该回滚", async function () {
      // 使合约USDT余额不足
      const largeAmount = ethers.utils.parseEther("100000000"); // 1亿USDT
      const largeAmounts = [
        largeAmount,
        largeAmount,
        largeAmount
      ];
      
      await expect(
        foMox.batchTransferUsdt(recipients, largeAmounts)
      ).to.be.revertedWith("Insufficient USDT balance");
      
      await expect(
        foMox.batchTransferUsdtSameAmount(recipients, largeAmount)
      ).to.be.revertedWith("Insufficient USDT balance");
    });
  });
});
