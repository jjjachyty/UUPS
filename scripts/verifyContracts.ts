import { ethers, run, upgrades } from "hardhat";
import { FoMox } from "../typechain-types";

async function main() {
  console.log("开始验证合约...");
  
  // 合约地址
  const proxyAddress = "0x9B96bfaCC0C79533d7eE987afB11E31091036e5B";
  
  try {
    // 1. 首先获取实现合约地址
    console.log("获取实现合约地址...");
    const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log(`实现合约地址: ${implAddress}`);
    
    // 2. 单独验证实现合约
    console.log("验证实现合约...");
    try {
      await run("verify:verify", {
        address: implAddress,
        // 不需要构造参数，因为实现合约的构造函数是空的
      });
      console.log("实现合约验证成功！");
    } catch (error: any) {
      if (error.message.includes("Already Verified")) {
        console.log("实现合约已经验证过，继续下一步...");
      } else {
        console.error("验证实现合约失败:", error);
        throw error;
      }
    }
    
    // 3. 验证代理合约并链接到实现
    console.log("验证代理合约...");
    try {
      // 获取初始化参数
      const FoMox = await ethers.getContractFactory("FoMox");
      const foMox = FoMox.attach(proxyAddress) as FoMox;
      
      // 获取USDT地址
      const usdtAddress = await foMox.usdtAddress();
      console.log(`USDT地址: ${usdtAddress}`);
      
      // 获取Router地址
      const routerAddress = await foMox.router();
      console.log(`Router地址: ${routerAddress}`);
      
      // 获取其他必要的地址
      const techAddress = await foMox.techAddress();
      const ecoAddress = await foMox.ecoAddress();
      const foPoolRewardAddress = await foMox.foPoolRewardAddress();
      const communityRewardAddress = await foMox.communityRewardAddress();
      
      // 获取池合约地址
      const foPoolAddress = await foMox.foPoolContract();
      const moPoolAddress = await foMox.moPoolContract();
      
      // 获取FToken地址
      const fTokenAddress = await foMox.fTokenContract();
      
      console.log("所有初始化参数已获取");
      
      // 使用verify:verify-proxy命令验证代理合约
      await run("verify:verify-proxy", {
        address: proxyAddress,
        constructorArguments: [
          usdtAddress,
          routerAddress,
          techAddress,
          ecoAddress,
          foPoolRewardAddress,
          communityRewardAddress,
          foPoolAddress,
          moPoolAddress,
          fTokenAddress
        ],
      });
      
      console.log("代理合约验证成功！");
    } catch (error: any) {
      if (error.message.includes("Already Verified")) {
        console.log("代理合约已经验证过");
      } else {
        console.error("验证代理合约失败:", error);
      }
    }
    
  } catch (error) {
    console.error("验证过程中发生错误:", error);
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
