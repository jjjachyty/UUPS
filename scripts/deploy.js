const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("开始部署FoMox合约系统...");

  // 部署模拟USDT（测试网使用）
  const MockUSDT = await ethers.getContractFactory("MockUSDT");
  const mockUSDT = await MockUSDT.deploy("Test USDT", "TUSDT", ethers.utils.parseEther("1000000"));
  await mockUSDT.deployed();
  console.log("MockUSDT已部署到:", mockUSDT.address);

  // 获取部署参数
  const [deployer] = await ethers.getSigners();
  
  // 示例地址，实际部署时应替换为真实地址
  const routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // PancakeSwap路由器地址
  const techAddress = deployer.address; // 技术维护地址
  const ecoAddress = deployer.address; // 生态地址
  const foPoolRewardAddress = deployer.address; // Fo池分红地址
  const communityRewardAddress = deployer.address; // 社区奖励地址
  const projectAddress = deployer.address; // 项目方地址

  // 部署FoMox实现合约和代理
  const FoMox = await ethers.getContractFactory("FoMox");
  console.log("正在部署FoMox代理合约...");
  
  // 使用UUPS代理模式部署
  const foMoxProxy = await upgrades.deployProxy(FoMox, [
    mockUSDT.address,
    routerAddress,
    techAddress,
    ecoAddress,
    foPoolRewardAddress,
    communityRewardAddress,
    projectAddress
  ], { 
    initializer: 'initialize',
    kind: 'uups'
  });
  
  await foMoxProxy.deployed();
  
  console.log("FoMox代理合约已部署到:", foMoxProxy.address);
  console.log("FoMox实现合约地址:", await upgrades.erc1967.getImplementationAddress(foMoxProxy.address));
  
  // 添加初始流动性
  console.log("正在添加初始流动性...");
  await foMoxProxy.addInitialLiquidity();
  
  console.log("部署完成，合约已初始化并添加流动性");
  console.log("------------------------------------");
  console.log("FoMox代理合约:", foMoxProxy.address);
  console.log("USDT合约:", mockUSDT.address);
  console.log("Router地址:", routerAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
