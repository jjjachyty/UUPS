import { ethers, upgrades } from "hardhat";
import { MoPool } from "../typechain-types";
import { FoMoxAddress, MoPolAddress,usdtAddress,routerAddress } from "./test"; 
async function main() {
  console.log("开始部署 MoPool 合约...");
  
  // 获取部署账户
  const [deployer] = await ethers.getSigners();
  console.log(`使用账户地址: ${deployer.address} 进行部署`);
  
  try {
 
    // 获取合约工厂
    const MoPool = await ethers.getContractFactory("MoPool");
    
    // 部署代理合约
    console.log("部署代理中...");
    const moPool = await upgrades.deployProxy(MoPool, 
      [
        FoMoxAddress,
        usdtAddress
      ], 
      { 
        initializer: 'initialize',
        kind: 'uups'
      }
    );
    
    await moPool.waitForDeployment();
    
    // 获取代理地址
    const MoPolAddress = await moPool.getAddress();
    console.log(`MoPool 代理合约地址: ${MoPolAddress}`);
    
    // 获取实现合约地址
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(MoPolAddress);
    console.log(`MoPool 实现合约地址: ${implementationAddress}`);
    
    console.log("MoPool 部署完成!");
// MoPool 代理合约地址: 0x5E231abD8d6DEA1cFbf59399eb6e3B2B306e586f
// MoPool 实现合约地址: 0x9e867f67cde043Acc93c2878fCCDC54b6e1D0f65
// MoPool 部署完成!
    // 返回合约地址便于后续使用
    return { proxy: MoPolAddress, implementation: implementationAddress };
  } catch (error) {
    console.error("部署过程中发生错误:", error);
    throw error;
  }
}

// 升级合约
async function upgradeMoPool(MoPolAddress: string) {
  try {
    console.log(`开始升级MoPool合约(${MoPolAddress})...`);
    
    const MoPool = await ethers.getContractFactory("MoPool");
    const upgraded = await upgrades.upgradeProxy(MoPolAddress, MoPool);
    
    await upgraded.waitForDeployment();
    const newImplementationAddress = await upgrades.erc1967.getImplementationAddress(MoPolAddress);
    
    console.log(`MoPool合约升级完成，新实现地址: ${newImplementationAddress}`);
    return newImplementationAddress;
  } catch (error) {
    console.error("升级过程中发生错误:", error);
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
runDeployment()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });


// setMoPolAddress()

// upgradeMoPool(MoPolAddress)