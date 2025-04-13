import { ethers, run, upgrades } from "hardhat";
import { FoMox } from "../typechain-types";
import fs from "fs";
import path from "path";

async function main() {
  console.log("开始手动验证合约...");
  
  // 合约地址 - 请替换为您的实现合约地址
  const implAddress = "0xce90294Ec41dF39092E2155f7cC6745b0E7De2D5";
  const proxyAddress = "0x9B96bfaCC0C79533d7eE987afB11E31091036e5B";

  try {
    // 强制重新编译
    await run("compile", { force: true });
    console.log("编译完成");
    
    // 创建临时配置以匹配部署时的编译器设置
    const tempConfigPath = createTemporaryHardhatConfig();
    console.log(`已创建临时配置文件: ${tempConfigPath}`);

    // 验证实现合约，使用多种方法尝试
    console.log(`验证实现合约: ${implAddress}`);
    
    try {
      // 方法1：指定具体合约路径
      console.log("尝试方法1：使用具体合约路径...");
      await run("verify:verify", {
        address: implAddress,
        contract: "contracts/FoMox.sol:FoMox" // 明确指定合约路径
      });
      console.log("实现合约验证成功");
    } catch (error1: any) {
      console.error("方法1失败:", error1.message);
      
      try {
        // 方法2：使用构造函数参数
        console.log("\n尝试方法2：添加构造函数参数...");
        await run("verify:verify", {
          address: implAddress,
          constructorArguments: [] // 实现合约的构造函数是空的
        });
        console.log("实现合约验证成功");
      } catch (error2: any) {
        console.error("方法2失败:", error2.message);
        
        try {
          // 方法3：使用flatten的合约代码
          console.log("\n尝试方法3：使用扁平化的代码验证...");
          
          // 首先扁平化合约
          await run("flatten", {
            files: ["./contracts/FoMox.sol"],
            output: "./FoMoxFlattened.sol"
          });
          
          // 手动指导用户在区块链浏览器上验证
          console.log("合约已扁平化为 FoMoxFlattened.sol");
          console.log("请在BSCScan上手动验证合约，使用扁平化后的代码");
          
        } catch (error3: any) {
          console.error("方法3失败:", error3.message);
          console.log("\n请尝试手动在BSC浏览器上验证合约");
        }
      }
    }
    
    // 获取部署时的构造函数参数
    console.log("\n尝试获取初始化参数...");
    const FoMox = await ethers.getContractFactory("FoMox");
    const foMox = FoMox.attach(proxyAddress) as FoMox;
  
    try {
      // 获取所有初始化参数
      const usdtAddress = await foMox.usdtAddress();
      const routerAddress = await foMox.router();
      const techAddress = await foMox.techAddress();
      const ecoAddress = await foMox.ecoAddress();
      const foPoolRewardAddress = await foMox.foPoolRewardAddress();
      const communityRewardAddress = await foMox.communityRewardAddress();
      const foPoolContract = await foMox.foPoolContract();
      const moPoolContract = await foMox.moPoolContract();
      
      // 打印所有参数
      console.log("初始化参数:");
      console.log(`usdtAddress: ${usdtAddress}`);
      console.log(`routerAddress: ${routerAddress}`);
      console.log(`techAddress: ${techAddress}`);
      console.log(`ecoAddress: ${ecoAddress}`);
      console.log(`foPoolRewardAddress: ${foPoolRewardAddress}`);
      console.log(`communityRewardAddress: ${communityRewardAddress}`);
      console.log(`foPoolContract: ${foPoolContract}`);
      console.log(`moPoolContract: ${moPoolContract}`);
      
      // 尝试获取fTokenContract地址
      try {
        const fTokenContract = await foMox.fTokenContract();
        console.log(`fTokenContract: ${fTokenContract}`);
      } catch (error) {
        console.log("无法获取fTokenContract地址");
      }
      
      // 构造验证参数
      console.log("\n初始化参数数组 (用于手动验证):");
      console.log(`[
  "${usdtAddress}",
  "${routerAddress}",
  "${techAddress}",
  "${ecoAddress}",
  "${foPoolRewardAddress}",
  "${communityRewardAddress}",
  "${foPoolContract}",
  "${moPoolContract}",
  "${await foMox.fTokenContract().catch(() => "0xE36CF4Aab15d778e6aAa44696369e29b77a84b2b")}"
]`);
      
    } catch (error) {
      console.log("无法获取所有参数，请检查合约是否兼容或手动提供参数");
      console.error(error);
    }
    
    // 清理临时文件
    cleanupTemporaryConfig(tempConfigPath);
    console.log("临时配置文件已删除");
    
    console.log("\n完成！您现在可以尝试在区块链浏览器上手动验证合约");
  } catch (error) {
    console.error("程序执行错误:", error);
  }
}

// 创建临时的hardhat配置文件，尝试匹配部署时的编译器设置
function createTemporaryHardhatConfig(): string {
  // 读取原始配置
  const originalConfigPath = path.join(process.cwd(), 'hardhat.config.ts');
  let configContent = fs.readFileSync(originalConfigPath, 'utf8');
  
  // 修改编译器设置
  configContent = configContent.replace(
    /solidity\s*:\s*{[^}]*}/g, 
    `solidity: {
      compilers: [
        {
          version: "0.8.19",
          settings: {
            optimizer: {
              enabled: true,
              runs: 200,
            },
            evmVersion: "paris"
          }
        },
        {
          version: "0.8.20",
          settings: {
            optimizer: {
              enabled: true,
              runs: 200,
            },
            evmVersion: "paris"
          }
        },
        {
          version: "0.8.18",
          settings: {
            optimizer: {
              enabled: true,
              runs: 200,
            },
            evmVersion: "paris"
          }
        }
      ]
    }`
  );
  
  // 写入临时文件
  const tempConfigPath = path.join(process.cwd(), 'hardhat.config.temp.ts');
  fs.writeFileSync(tempConfigPath, configContent, 'utf8');
  
  return tempConfigPath;
}

// 清理临时配置文件
function cleanupTemporaryConfig(tempConfigPath: string): void {
  if (fs.existsSync(tempConfigPath)) {
    fs.unlinkSync(tempConfigPath);
  }
}

// 执行主函数
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
