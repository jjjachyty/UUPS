import { ethers, upgrades } from "hardhat";
import { FoPool } from "../typechain-types";

const ProxyAddress = "0x2D9be4288334B8E0690b051129fdcca7736695c4"; // MoPool 代理合约地址
const FoMoxAddress = "0x9B96bfaCC0C79533d7eE987afB11E31091036e5B"; // FoMox 代理合约地址

async function main() {
  console.log("开始部署 FoPool 合约...");
  
  // 获取部署账户
  const [deployer] = await ethers.getSigners();
  console.log(`使用账户地址: ${deployer.address} 进行部署`);
  
  try {
    // 配置需要的地址
     const usdtAddress = "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684"; // 测试网USDT地址
    const routerAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; // PancakeSwap路由器地址 - 测试网
    const fTokenAddress = "0xd012DC80dF41A5706F691adD47502771961EF138"; // FToken地址
    
    // 获取合约工厂
    const FoPool = await ethers.getContractFactory("FoPool");
    
    // 部署代理合约
    console.log("部署代理中...");
    const foPool = await upgrades.deployProxy(FoPool, 
      [
        FoMoxAddress,
        usdtAddress,
        routerAddress, 
        fTokenAddress
      ], 
      { 
        initializer: 'initialize',
        kind: 'uups'
      }
    );
    
    await foPool.waitForDeployment();
    
    // 获取代理地址
    const proxyAddress = await foPool.getAddress();
    console.log(`FoPool 代理合约地址: ${proxyAddress}`);
    
    // 获取实现合约地址
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log(`FoPool 实现合约地址: ${implementationAddress}`);
    
    console.log("FoPool 部署完成!");
//     FoPool 代理合约地址: 0x2D9be4288334B8E0690b051129fdcca7736695c4
// FoPool 实现合约地址: 0xfe865f29DA9CaaeF431aB0268edB1f58c78CdC60
// FoPool 部署完成!
    // 返回合约地址便于后续使用
    return { proxy: proxyAddress, implementation: implementationAddress };
  } catch (error) {
    console.error("部署过程中发生错误:", error);
    throw error;
  }
}

// 升级合约
async function upgradeFoPool(proxyAddress: string) {
  try {
    console.log(`开始升级FoPool合约(${proxyAddress})...`);
    
    const FoPool = await ethers.getContractFactory("FoPool");
    const upgraded = await upgrades.upgradeProxy(proxyAddress, FoPool);
    
    await upgraded.waitForDeployment();
    const newImplementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    
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



async function setFoMoxAddress() {
  try {
    console.log(`开始设置FoPool合约(${ProxyAddress})的FoMox地址...`);
    const FoPool = await ethers.getContractAt("FoPool", ProxyAddress) as FoPool;
     await FoPool.setFomoxAddress(FoMoxAddress);
    console.log("已设置FoMox地址");
  } catch (error) {
    console.error("设置过程中发生错误:", error);
    throw error;
  }
}



async function setMinDepositAmount() {
  try {
    console.log(`开始设置FoPool合约(${ProxyAddress})的最小存款金额...`);
    const FoPool = await ethers.getContractAt("FoPool", ProxyAddress) as FoPool;
    const minDepositAmount = ethers.parseUnits("0.01", 18); // 最小存款金额
    await FoPool.setMinDeposit(minDepositAmount);
    console.log("已设置最小存款金额");
  } catch (error) {
    console.error("设置过程中发生错误:", error);
    throw error;
  }
}

// setMinDepositAmount()

// setFoMoxAddress()

upgradeFoPool(ProxyAddress);