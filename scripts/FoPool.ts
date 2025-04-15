import { ethers, upgrades } from "hardhat";
import { FoPool } from "../typechain-types";
import { usdtAddress,FoMoxAddress,routerAddress,FoPoolAddress } from "./test";

// const FoPoolAddress = "0x2D9be4288334B8E0690b051129fdcca7736695c4"; // MoPool 代理合约地址
// const FoMoxAddress = "0x9B96bfaCC0C79533d7eE987afB11E31091036e5B"; // FoMox 代理合约地址

async function main() {
  console.log("开始部署 FoPool 合约...");
  
  // 获取部署账户
  const [deployer] = await ethers.getSigners();
  console.log(`使用账户地址: ${deployer.address} 进行部署`);
  
  try {
    
    // 获取合约工厂
    const FoPool = await ethers.getContractFactory("FoPool");
    
    // 部署代理合约
    console.log("部署代理中...");
    const foPool = await upgrades.deployProxy(FoPool, 
      [
        FoMoxAddress,
        usdtAddress,
        routerAddress
       ], 
      { 
        initializer: 'initialize',
        kind: 'uups'
      }
    );
    
    await foPool.waitForDeployment();
    
    // 获取代理地址
    const FoPoolAddress = await foPool.getAddress();
    console.log(`FoPool 代理合约地址: ${FoPoolAddress}`);
    
    // 获取实现合约地址
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(FoPoolAddress);
    console.log(`FoPool 实现合约地址: ${implementationAddress}`);
    
    console.log("FoPool 部署完成!");
//     FoPool 代理合约地址: 0x2D9be4288334B8E0690b051129fdcca7736695c4
// FoPool 实现合约地址: 0xfe865f29DA9CaaeF431aB0268edB1f58c78CdC60
// FoPool 部署完成!
    // 返回合约地址便于后续使用
    return { proxy: FoPoolAddress, implementation: implementationAddress };
  } catch (error) {
    console.error("部署过程中发生错误:", error);
    throw error;
  }
}

// 升级合约
async function upgradeFoPool( ) {
  try {
    console.log(`开始升级FoPool合约(${FoPoolAddress})...`);
    
    const FoPool = await ethers.getContractFactory("FoPool");
    const upgraded = await upgrades.upgradeProxy(FoPoolAddress, FoPool);
    
    await upgraded.waitForDeployment();
    const newImplementationAddress = await upgrades.erc1967.getImplementationAddress(FoPoolAddress);
    
    console.log(`FoPool合约升级完成，新实现地址: ${newImplementationAddress}`);
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
    // await upgradeFoPool(proxy);
  } catch (error) {
    console.error("执行过程中发生错误:", error);
    process.exitCode = 1;
  }
}


// // 启动部署流程
// runDeployment()
//   .then(() => process.exit(0))
//   .catch(error => {
//     console.error(error);
//     process.exit(1);
//   });

// setMinDepositAmount()

// setFoMoxAddress()

upgradeFoPool();