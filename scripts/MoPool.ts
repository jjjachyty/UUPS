import { ethers, upgrades } from "hardhat";
import { MoPool } from "../typechain-types";
const foMoxAddress = "0x9B96bfaCC0C79533d7eE987afB11E31091036e5B";
const ProxyAddress = "0x5E231abD8d6DEA1cFbf59399eb6e3B2B306e586f"; // MoPool 代理合约地址

async function main() {
  console.log("开始部署 MoPool 合约...");
  
  // 获取部署账户
  const [deployer] = await ethers.getSigners();
  console.log(`使用账户地址: ${deployer.address} 进行部署`);
  
  try {
    // 配置需要的地址
     const usdtAddress = "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684"; // 测试网USDT地址
    const routerAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; // PancakeSwap路由器地址 - 测试网
    
    // 获取合约工厂
    const MoPool = await ethers.getContractFactory("MoPool");
    
    // 部署代理合约
    console.log("部署代理中...");
    const moPool = await upgrades.deployProxy(MoPool, 
      [
        foMoxAddress,
        usdtAddress,
        routerAddress
      ], 
      { 
        initializer: 'initialize',
        kind: 'uups'
      }
    );
    
    await moPool.waitForDeployment();
    
    // 获取代理地址
    const proxyAddress = await moPool.getAddress();
    console.log(`MoPool 代理合约地址: ${proxyAddress}`);
    
    // 获取实现合约地址
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log(`MoPool 实现合约地址: ${implementationAddress}`);
    
    console.log("MoPool 部署完成!");
// MoPool 代理合约地址: 0x5E231abD8d6DEA1cFbf59399eb6e3B2B306e586f
// MoPool 实现合约地址: 0x9e867f67cde043Acc93c2878fCCDC54b6e1D0f65
// MoPool 部署完成!
    // 返回合约地址便于后续使用
    return { proxy: proxyAddress, implementation: implementationAddress };
  } catch (error) {
    console.error("部署过程中发生错误:", error);
    throw error;
  }
}

// 升级合约
async function upgradeMoPool(proxyAddress: string) {
  try {
    console.log(`开始升级MoPool合约(${proxyAddress})...`);
    
    const MoPool = await ethers.getContractFactory("MoPool");
    const upgraded = await upgrades.upgradeProxy(proxyAddress, MoPool);
    
    await upgraded.waitForDeployment();
    const newImplementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    
    console.log(`MoPool合约升级完成，新实现地址: ${newImplementationAddress}`);
    return newImplementationAddress;
  } catch (error) {
    console.error("升级过程中发生错误:", error);
    throw error;
  }
}


async function setFoMoxAddress() {
  try {
    console.log(`开始设置MoPool合约(${ProxyAddress})的FoMox地址...`);
    const MoPool = await ethers.getContractAt("MoPool", ProxyAddress) as MoPool;
     // FoMox地址
    await MoPool.setFomoxAddress(foMoxAddress);
    console.log("已设置FoMox地址");
  } catch (error) {
    console.error("设置过程中发生错误:", error);
    throw error;
  }
}

// 执行主部署函数
async function runDeployment() {
  try {
    // 部署合约
    const { proxy } = await main();
    
    // 如果需要，可以在此调用upgrade函数
    // await upgradeMoPool(proxy);
  } catch (error) {
    console.error("执行过程中发生错误:", error);
    process.exitCode = 1;
  }
}

// 启动部署流程
// runDeployment()
//   .then(() => process.exit(0))
//   .catch(error => {
//     console.error(error);
//     process.exit(1);
//   });


// setFoMoxAddress()

upgradeMoPool(ProxyAddress)