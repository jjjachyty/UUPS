import { FToken } from "../typechain-types";

const { ethers, upgrades } = require("hardhat");
const ProxyAddress = "0xE36CF4Aab15d778e6aAa44696369e29b77a84b2b"; // MoPool 代理合约地址
const FoMoxAddress = "0x9B96bfaCC0C79533d7eE987afB11E31091036e5B"; // FoMox 代理合约地址
async function main() {
  console.log("开始部署 FToken 合约...");
  
  // 获取部署账户
  const [deployer] = await ethers.getSigners();
  console.log(`使用账户地址: ${deployer.address} 进行部署`);
  
  try {
    // 获取合约工厂
    const FToken = await ethers.getContractFactory("FToken");
    
    // 准备初始化参数 - 根据FToken合约实际需要的参数调整
    const usdtAddress = "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684"; // 或其他指定地址
    const router = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; // 或其他指定地址
    
    // 部署代理合约
    console.log("部署代理中...");
    const fToken = await upgrades.deployProxy(FToken, 
      [usdtAddress,router], // 根据FToken.initialize的实际参数进行调整
      { 
        initializer: 'initialize',
        kind: 'uups'
      }
    );
    
    await fToken.waitForDeployment();
    
    // 获取代理地址
    const proxyAddress = await fToken.getAddress();
    console.log(`FToken 代理合约地址: ${proxyAddress}`);
    
    // 获取实现合约地址
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log(`FToken 实现合约地址: ${implementationAddress}`);
    
    console.log("FToken 部署完成!");

// FToken 代理合约地址: 0xd012DC80dF41A5706F691adD47502771961EF138
// FToken 实现合约地址: 0x1bf0500897063341A9B73279D246F8200B59DA21
// FToken 部署完成!

    // 返回合约地址便于后续使用
    return { proxy: proxyAddress, implementation: implementationAddress };
  } catch (error) {
    console.error("部署过程中发生错误:", error);
    throw error;
  }
}

// 初始化FToken合约地址设置
async function initAddress(proxyAddress:string) {
  try {
    console.log(`开始初始化FToken合约(${proxyAddress})...`);
    
    const FToken = await ethers.getContractAt("FToken", proxyAddress);
    
    // 设置各种地址
    await FToken.setFoPoolAddress("0x253e249A734cabA69eB1fe59B0Ad5337599Deddc");
    console.log("已设置FoPool地址");
    
    await FToken.setFoMoxAddress("0xf5d298A16237a7F8Ef692DA6EFB629BC6b8D5538");
    console.log("已设置FoMox地址");
    
    await FToken.setMoPoolAddress("0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684");
    console.log("已设置MoPool地址");
    
    // 设置交易限制豁免地址
    const exemptAddresses = [
      "0xf5d298A16237a7F8Ef692DA6EFB629BC6b8D5538", // FoMox地址
      "0x253e249A734cabA69eB1fe59B0Ad5337599Deddc", // FoPool地址
      "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684"  // MoPool地址
      // 添加其他需要豁免的地址
    ];
    
    await FToken.setIsExemptFromTransferRestrictions(exemptAddresses, true);
    console.log("已设置豁免地址");
    
    console.log("FToken合约初始化完成");
  } catch (error) {
    console.error("初始化过程中发生错误:", error);
    throw error;
  }
}

// 升级合约
async function upgrade() {
  try {
    console.log(`开始升级FToken合约(${ProxyAddress})...`);
    
    const FToken = await ethers.getContractFactory("FToken");
    const upgraded = await upgrades.upgradeProxy(ProxyAddress, FToken);
    
    await upgraded.waitForDeployment();
    const newImplementationAddress = await upgrades.erc1967.getImplementationAddress(ProxyAddress);
    
    console.log(`FToken合约升级完成，新实现地址: ${newImplementationAddress}`);
    return newImplementationAddress;
  } catch (error) {
    console.error("升级过程中发生错误:", error);
    throw error;
  }
}

// 执行主函数
async function runDeployment() {
  try {
    // 部署合约
    const { proxy } = await main();
    
    // 初始化合约
    // await initAddress(proxy);
    
    // 如果需要，可以在此调用upgrade函数
    // await upgrade(proxy);
  } catch (error) {
    console.error("执行过程中发生错误:", error);
    process.exitCode = 1;
  }
}

async function checkReference(address:string) {
  var fToken = await ethers.getContractAt("FToken",ProxyAddress) as FToken;
  const reference = await fToken.referrers(address);
  console.log("地址",address,"上级",reference);
}

async function setFoPoolAddress(address:string) {
  var fToken = await ethers.getContractAt("FToken","0xd012DC80dF41A5706F691adD47502771961EF138") as FToken;
  const tx = await fToken.setFoPoolAddress(address);
  console.log("设置FoPool地址交易哈希:", tx.hash);
}
async function setFoMoxAddress() {
  try {
    console.log(`开始设置FToken合约(${ProxyAddress})的FoMox地址...`);
    const FToken = await ethers.getContractAt("FToken", ProxyAddress) as FToken;
     await FToken.setFoMoxAddress(FoMoxAddress);
    console.log("已设置FoMox地址");
  } catch (error) {
    console.error("设置过程中发生错误:", error);
    throw error;
  }
}


// async function setRouter(address:string) {
//   var fToken = await ethers.getContractAt("FToken",ProxyAddress) as FToken;
//   const tx = await fToken.setRouter(address);
//   console.log("设置路由地址交易哈希:", tx.hash);
// }

async function processReferralRewards() {
  var fToken = await ethers.getContractAt("FToken",ProxyAddress) as FToken;
  const tx = await fToken.processReferralRewards();
  console.log("处理推荐奖励交易哈希:", tx.hash);
}
// processReferralRewards();
// 启动部署流程
// runDeployment();
upgrade()
// checkReference("0x08bB8398F32A7E7cE5A2567D5861DEf6465c62f9")
// setFoPoolAddress("0x2D9be4288334B8E0690b051129fdcca7736695c4")
// setFoMoxAddress()
// setRouter("0xD99D1c33F9fC3444f8101754aBC46c52416550D1")