const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("FToken", function () {
  let FToken, fToken, FoMox, foMox;
  let owner, user1, user2, user3;
  let initialSupply = ethers.parseEther("10000000"); // 1000万枚代币

  beforeEach(async function () {
    // 获取测试账户
    [owner, user1, user2, user3, ...addrs] = await ethers.getSigners();
    
    // 部署F代币
    FToken = await ethers.getContractFactory("FToken");
    fToken = await upgrades.deployProxy(FToken, [initialSupply], { 
      initializer: 'initialize',
      kind: 'uups'
    });
    console.log("FToken合约地址:", fToken.target);
     
    // 部署FoMox合约（简化版，仅用于测试推荐关系）
    FoMox = await ethers.getContractFactory("FoMox");
    foMox = await upgrades.deployProxy(FoMox, [
      "0x55d398326f99059fF775485246999027B3197955", // 模拟USDT地址
      "0x10ED43C718714eb63d5aA57B78B54704E256024E", // 模拟路由器地址
      owner.address,
      owner.address,
      owner.address,
      owner.address
    ], { 
      initializer: 'initialize',
      kind: 'uups'
    });
     
    // 设置合约互相关联
    await fToken.setFoMoxAddress(foMox.target);
    await foMox.setFTokenAddress(fToken.target);
  });

  describe("基本功能", function () {
    it("初始化后应该将代币分配给部署者", async function () {
      expect(await fToken.balanceOf(owner.address)).to.equal(initialSupply);
      expect(await fToken.name()).to.equal("F Token");
      expect(await fToken.symbol()).to.equal("F");
    });

    it("所有者可以增发代币", async function () {
      const mintAmount = ethers.utils.parseEther("1000");
      await fToken.mint(user1.address, mintAmount);
      expect(await fToken.balanceOf(user1.address)).to.equal(mintAmount);
    });

    it("非所有者不能增发代币", async function () {
      const mintAmount = ethers.utils.parseEther("1000");
      await expect(fToken.connect(user1).mint(user1.address, mintAmount))
        .to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("推荐关系绑定", function () {
    it("用户转账1个F代币可以建立推荐关系", async function () {
      // 向用户1转一些代币
      await fToken.transfer(user1.address, ethers.utils.parseEther("10"));
      
      // 用户1使用F代币向用户2转1个代币建立推荐关系
      await fToken.connect(user1).transfer(user2.address, ethers.utils.parseEther("1"));
      
      // 验证推荐关系已建立
      expect(await foMox.referrers(user2.address)).to.equal(user1.address);
      expect(await foMox.referralCount(user1.address)).to.equal(1);
    });

    it("转账不是1个F代币不会建立推荐关系", async function () {
      // 向用户1转一些代币
      await fToken.transfer(user1.address, ethers.utils.parseEther("10"));
      
      // 用户1向用户2转2个代币，不会建立推荐关系
      await fToken.connect(user1).transfer(user2.address, ethers.utils.parseEther("2"));
      
      // 验证没有建立推荐关系
      expect(await foMox.referrers(user2.address)).to.equal("0x0000000000000000000000000000000000000000");
    });

    it("已有推荐人的用户不会被重新绑定", async function () {
      // 向用户1和用户3转一些代币
      await fToken.transfer(user1.address, ethers.utils.parseEther("10"));
      await fToken.transfer(user3.address, ethers.utils.parseEther("10"));
      
      // 用户1先和用户2建立推荐关系
      await fToken.connect(user1).transfer(user2.address, ethers.utils.parseEther("1"));
      
      // 用户3尝试和用户2建立推荐关系，应该不成功
      await fToken.connect(user3).transfer(user2.address, ethers.utils.parseEther("1"));
      
      // 验证用户2的推荐人仍然是用户1
      expect(await foMox.referrers(user2.address)).to.equal(user1.address);
    });
  });
});
