import { FToken } from "../typechain-types";
import { usdtAddress,routerAddress,FTokenAddress } from "./test";

const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("开始部署 FToken 合约...");
  
  // 获取部署账户
  const [deployer] = await ethers.getSigners();
  console.log(`使用账户地址: ${deployer.address} 进行部署`);
  
  try {
    // 获取合约工厂
    const FToken = await ethers.getContractFactory("FToken");
    
    // 部署代理合约
    console.log("部署代理中...");
    const fToken = await upgrades.deployProxy(FToken, 
      [usdtAddress], 
      { 
        initializer: 'initialize',
        kind: 'uups'
      }
    );
    
    await fToken.waitForDeployment();
    
    // 获取代理地址 - 使用兼容的方法
    const FTokenAddress = await fToken.getAddress();
    console.log(`FToken 代理合约地址: ${FTokenAddress}`);
    
    // 获取实现合约地址
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(FTokenAddress);
    console.log(`FToken 实现合约地址: ${implementationAddress}`);
    
    console.log("FToken 部署完成!");

    // 返回合约地址便于后续使用
    return { proxy: FTokenAddress, implementation: implementationAddress };
  } catch (error) {
    console.error("部署过程中发生错误:", error);
    throw error;
  }
}

// 初始化FToken合约地址设置
async function initAddress(FTokenAddress:string) {
  try {
    console.log(`开始初始化FToken合约(${FTokenAddress})...`);
    
    const FToken = await ethers.getContractAt("FToken", FTokenAddress);
    
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
    console.log(`开始升级FToken合约(${FTokenAddress})...`);
    
    const FToken = await ethers.getContractFactory("FToken");
    const upgraded = await upgrades.upgradeProxy(FTokenAddress, FToken);
    
    await upgraded.waitForDeployment();
    const newImplementationAddress = await upgrades.erc1967.getImplementationAddress(FTokenAddress);
    
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

// 修改合约交互方式，避免使用DNS解析功能
async function checkReference(address:string) {
  const fToken = await ethers.getContractAt("FToken", FTokenAddress);
  const reference = await fToken.referrers(address);
  console.log("地址",address,"上级",reference);
}

async function setFoPoolAddress(address:string) {
  const fToken = await ethers.getContractAt("FToken", "0xd012DC80dF41A5706F691adD47502771961EF138");
  const tx = await fToken.setFoPoolAddress(address);
  console.log("设置FoPool地址交易哈希:", tx.hash);
}

 

 
// processReferralRewards();
// 启动部署流程
runDeployment();
// upgrade()
// checkReference("0x08bB8398F32A7E7cE5A2567D5861DEf6465c62f9")
// setFoPoolAddress("0x2D9be4288334B8E0690b051129fdcca7736695c4")
// setFoMoxAddress()
// setRouter("0xD99D1c33F9fC3444f8101754aBC46c52416550D1")