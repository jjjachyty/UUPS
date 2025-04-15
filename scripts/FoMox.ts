import { ethers, upgrades } from "hardhat";
import { Contract } from "ethers";
import { FoMox, IUniswapV2Router02 } from "../typechain-types";
import { usdtAddress, routerAddress, techAddress, ecoAddress, foPoolRewardAddress, communityRewardAddress, FoPoolAddress, MoPoolAddress,FTokenAddress, FoMoxAddress } from "./test";

  
async function main() {
  console.log("开始部署 FoMox 合约...");
  
  // 获取部署账户
  const [deployer] = await ethers.getSigners();
  console.log(`使用账户地址: ${deployer.address} 进行部署`);
  
  try {
   
    
    // 获取合约工厂
    const FoMox = await ethers.getContractFactory("FoMox");
    
    // 部署代理合约
    console.log("部署代理中...");
    const foMox = await upgrades.deployProxy(FoMox, 
      [
        usdtAddress,
        routerAddress,
        techAddress,
        ecoAddress,
        foPoolRewardAddress,
        communityRewardAddress,
        FoPoolAddress,
        MoPoolAddress,
        FTokenAddress
      ], 
      { 
        initializer: 'initialize',
        kind: 'uups'
      }
    );
    
    await foMox.waitForDeployment();
    
    // 获取代理地址
    const proxyAddress = await foMox.getAddress();
    console.log(`FoMox 代理合约地址: ${proxyAddress}`);
    
    // 获取实现合约地址
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log(`FoMox 实现合约地址: ${implementationAddress}`);
    
    console.log("FoMox 部署完成!");
//     FoMox 代理合约地址: 0xa5A33b0FA51407cB499b6Ca9fFEa291B8CF8A22a
// FoMox 实现合约地址: 0xEA4BCeB42c4103a5a6682A791d02A9F69Bb112a5
// FoMox 部署完成!
    // 返回合约地址便于后续使用
    return { proxy: proxyAddress, implementation: implementationAddress };
  } catch (error) {
    console.error("部署过程中发生错误:", error);
    throw error;
  }
}

// 初始化FoMox合约设置
async function initializeSettings(foMoxAddress: string) {
  try {
    console.log(`开始初始化FoMox合约(${foMoxAddress})...`);
    
    const foMox = await ethers.getContractAt("FoMox", foMoxAddress);
    
    // 设置白名单地址
    const whitelistAddresses = [
      "0x10ED43C718714eb63d5aA57B78B54704E256024E", // PancakeSwap路由器
      "0x55d398326f99059fF775485246999027B3197955", // USDT地址
      // 添加其他需要白名单的地址
    ];
    
    for (const addr of whitelistAddresses) {
      await foMox.setWhiteAddress(addr, true);
      console.log(`已将 ${addr} An设置为白名单地址`);
    }
    
    // 设置价格控制参数
    console.log("设置价格控制参数...");
    const minLiquidities = [0, 5 * 10**4 * 10**18, 10 * 10**4 * 10**18, 20 * 10**4 * 10**18, 50 * 10**4 * 10**18];
    const maxLiquidities = [5 * 10**4 * 10**18, 10 * 10**4 * 10**18, 20 * 10**4 * 10**18, 50 * 10**4 * 10**18, ethers.MaxUint256];
    const maxDailyIncreases = [20, 15, 10, 8, 5];
    const triggerDecreasePercents = [10, 10, 5, 5, 5];
    
    await foMox.updatePriceControlTiers(
      minLiquidities,
      maxLiquidities,
      maxDailyIncreases,
      triggerDecreasePercents
    );
    
    // 设置今日开始价格
    await foMox.setTodayStartPrice();
    console.log("已设置今日开始价格");
    
    console.log("FoMox合约初始化完成");
  } catch (error) {
    console.error("初始化过程中发生错误:", error);
    throw error;
  }
}

// 升级合约
async function upgradeFoMox(forcedUpgrade = false) {
  try {
    console.log(`开始升级FoMox合约(${FoMoxAddress})...`);
    
    const FoMox = await ethers.getContractFactory("FoMox");
    
    // 根据参数决定是否强制升级
    let upgraded;
    if (forcedUpgrade) {
      console.log("警告：使用强制升级模式，这可能导致数据损坏");
      upgraded = await upgrades.forceImport(FoMoxAddress, FoMox);
    } else {
      console.log("使用安全升级模式");
      upgraded = await upgrades.upgradeProxy(FoMoxAddress, FoMox);
    }
    
    await upgraded.waitForDeployment();
    const newImplementationAddress = await upgrades.erc1967.getImplementationAddress(FoMoxAddress);
    
    console.log(`FoMox合约升级完成，新实现地址: ${newImplementationAddress}`);
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
    
    // 初始化合约设置 
    // 注释掉以防止在测试环境误操作
    // await initializeSettings(proxy);
    
    // 如果需要，可以在此调用upgrade函数
    // await upgradeFoMox(proxy);
  } catch (error) {
    console.error("执行过程中发生错误:", error);
    process.exitCode = 1;
  }
}

async function getCurrentPrice() {
  try {
    console.log(`开始获取FoMox合约(${FoMoxAddress})的当前价格...`);
    const FoMox = await ethers.getContractAt("FoMox", FoMoxAddress) as FoMox;
    const currentPrice = await FoMox.getCurrentPrice();
    const todayStartPrice  =  await FoMox.todayStartPrice();

    console.log(`当日价格 ${todayStartPrice} 当前价格: ${ethers.formatUnits(currentPrice, 18)}`);
  } catch (error) {
    console.error("获取过程中发生错误:", error);
    throw error;
  }
}

async function setMinDepositAmount() {
  try {
    console.log(`开始设置FoPool合约(${FoMoxAddress})的最小存款金额...`);
    const FoPool = await ethers.getContractAt("FoMox", FoMoxAddress) as FoMox;
     await FoPool.setMinDepost(ethers.parseEther("0.01"));
    console.log("已设置最小存款金额");
  } catch (error) {
    console.error("设置过程中发生错误:", error);
    throw error;
  }
}
async function setWhiteAddress(address:string,flag:boolean) {
  try {
    console.log(`开始设置FoPool合约(${FoMoxAddress})的白名单地址...`);
    const FoPool = await ethers.getContractAt("FoMox", FoMoxAddress) as FoMox;
     await FoPool.setWhiteAddress(address, flag);
    console.log("已设置白名单地址");
  } catch (error) {
    console.error("设置过程中发生错误:", error);
    throw error;
  }
}


async function checkDailyPriceLimit() {
  try {
    console.log(`开始检查每日价格限制...`);
    const FoMox = await ethers.getContractAt("FoMox", FoMoxAddress) as FoMox;
    const dailyPriceLimit = await FoMox.checkDailyPriceLimit();
    console.log(`每日价格限制: ${dailyPriceLimit}`);
  } catch (error) {
    console.error("检查过程中发生错误:", error);
    throw error;
  }
}
 

// 添加一个新函数来设置或检查配对
async function setupAndCheckPair() {
  try {
    console.log("检查和设置交易对...");
    
    const [user] = await ethers.getSigners();
    console.log(`使用账户地址: ${user.address}`);
    
    const usdtAddress = "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684"; 
    const routerAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    const foMox = await ethers.getContractAt("FoMox", FoMoxAddress) as FoMox;
    const router = await ethers.getContractAt("IUniswapV2Router02", routerAddress) as IUniswapV2Router02;
    const usdt = await ethers.getContractAt("IERC20", usdtAddress);
    
    // 检查路由器合约
    console.log("路由器地址:", routerAddress);
    const factory = await router.factory();
    console.log("工厂合约地址:", factory);
    
    // 检查代币对是否存在
    let pairAddress = await foMox.uniswapPair();
    console.log("当前交易对地址:", pairAddress);
    
    if (pairAddress === ethers.ZeroAddress) {
      console.log("交易对未设置，尝试创建...");
      const factoryContract = await ethers.getContractAt("IUniswapV2Factory", factory);
      pairAddress = await factoryContract.getPair(FoMoxAddress, usdtAddress);
      
      if (pairAddress === ethers.ZeroAddress) {
        console.log("交易对不存在，正在创建...");
        await factoryContract.createPair(FoMoxAddress, usdtAddress);
        pairAddress = await factoryContract.getPair(FoMoxAddress, usdtAddress);
      }
      
      console.log("设置交易对地址:", pairAddress);
      await foMox.setUniswapPairAddress(pairAddress);
    }
    
    // 检查流动性
    try {
      const pair = await ethers.getContractAt("IUniswapV2Pair", pairAddress);
      const [reserve0, reserve1] = await pair.getReserves();
      console.log("交易对储备:", ethers.formatUnits(reserve0, 18), ethers.formatUnits(reserve1, 18));
      
      // 检查是否需要添加流动性
      if (reserve0.toString() === '0' || reserve1.toString() === '0') {
        console.log("流动性不足，需要添加初始流动性");
        
        // 添加初始流动性的逻辑
        const initialTokenAmount = ethers.parseUnits("1000", 18); // 1000 tokens
        const initialUsdtAmount = ethers.parseUnits("0.1", 18); // 0.1 USDT
        
        // 确保我们有足够的代币
        const tokenBalance = await foMox.balanceOf(user.address);
        const usdtBalance = await usdt.balanceOf(user.address);
        
        console.log("您的代币余额:", ethers.formatUnits(tokenBalance, 18));
        console.log("您的USDT余额:", ethers.formatUnits(usdtBalance, 18));
        
        if (tokenBalance < initialTokenAmount || usdtBalance < initialUsdtAmount) {
          console.log("余额不足，无法添加流动性");
          return false;
        }
        
        // 批准代币转账
        await foMox.connect(user).approve(routerAddress, initialTokenAmount);
        await usdt.connect(user).approve(routerAddress, initialUsdtAmount);
        
        console.log("添加初始流动性...");
        await router.connect(user).addLiquidity(
          FoMoxAddress,
          usdtAddress,
          initialTokenAmount,
          initialUsdtAmount,
          0, // slippage is unavoidable
          0, // slippage is unavoidable
          user.address,
          Math.floor(Date.now() / 1000) + 60 * 20
        );
        
        console.log("初始流动性已添加");
      }
      
      return true;
    } catch (error) {
      console.error("获取或设置流动性时出错:", error);
      return false;
    }
  } catch (error) {
    console.error("检查交易对时出错:", error);
    return false;
  }
}

// 修改模拟购买函数
async function simulatePancakeSwapBuy() {
  try {
    console.log("开始模拟PancakeSwap买入操作...");
    
    // 首先检查和设置交易对
    const pairReady = await setupAndCheckPair();
    if (!pairReady) {
      throw new Error("交易对设置失败，无法继续");
    }
    
    // 获取部署账户
    const [user] = await ethers.getSigners();
    console.log(`测试账户地址: ${user.address}`);
    
    // 配置需要的地址
    const usdtAddress = "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684"; 
    const routerAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; 
    const foMoxAddress = FoMoxAddress;
    
    // 获取合约实例
    const usdt = await ethers.getContractAt("IERC20", usdtAddress);
    const router = await ethers.getContractAt("IUniswapV2Router02", routerAddress) as IUniswapV2Router02;
    const foMox = await ethers.getContractAt("FoMox", foMoxAddress) as FoMox;
    
    // 使用非常小的金额测试
    const amountToSpend = ethers.parseUnits("0.01", 18); // 0.001 USDT
    console.log(`准备用 ${ethers.formatUnits(amountToSpend, 18)} USDT 购买FoMox`);
    
    // 检查USDT余额
    const userUsdtBalance = await usdt.balanceOf(user.address);
    console.log(`用户USDT余额: ${ethers.formatUnits(userUsdtBalance, 18)}`);
    
    if (userUsdtBalance < amountToSpend) {
      throw new Error("USDT余额不足，请先获取一些测试USDT");
    }
    
    // 极大增加授权金额，确保不会因为授权不足而失败
    await usdt.connect(user).approve(routerAddress, amountToSpend * BigInt(100));
    console.log("已批准路由器使用USDT，授权金额为请求的100倍");
    
    // 设置交易参数
    const deadline = Math.floor(Date.now() / 1000) + 60 * 60; // 1小时过期时间
    const slippageTolerance = 9900; // 99%的滑点容忍度，接近任何价格
    
    // 设置交易路径
    const path = [usdtAddress, foMoxAddress];
    console.log("交易路径:", path);
    
    try {
      console.log("尝试获取估计输出量...");
      const amountsOut = await router.getAmountsOut(amountToSpend, path);
      console.log("估计输出量:", ethers.formatUnits(amountsOut[1], 18));
      
      const minAmountOut = amountsOut[1] * BigInt(10000 - slippageTolerance) / BigInt(10000);
      console.log("最小输出量:", ethers.formatUnits(minAmountOut, 18));
      
      console.log("尝试使用supportingFeeOnTransferTokens函数...");
      const tx = await router.connect(user).swapExactTokensForTokensSupportingFeeOnTransferTokens(
        amountToSpend,
        0, // 接受任何数量的输出
        path,
        user.address,
        deadline,
        { gasLimit: 3000000 } // 增加gas限制
      );
      
      console.log("交易已提交，等待确认...");
      await tx.wait();
      console.log(`交易已确认: ${tx.hash}`);
      
      // 检查交易后FoMox余额
      const finalFoMoxBalance = await foMox.balanceOf(user.address);
      console.log(`最终FoMox余额: ${ethers.formatUnits(finalFoMoxBalance, 18)}`);
      
      console.log("测试买入操作完成");
      return true;
    } catch (error) {
      console.error("交换操作失败，详细错误:", error);
      
      // 尝试直接从合约购买
      console.log("尝试直接通过合约购买...");
      try {
        // 批准合约使用USDT
        await usdt.connect(user).approve(foMoxAddress, amountToSpend);
        
        // 调用合约的购买函数 (如果有的话)
        // 这里需要实现一个直接购买的合约函数
        
        console.log("直接购买失败，请确保合约有直接购买功能");
        return false;
      } catch (directError) {
        console.error("直接购买也失败:", directError);
        return false;
      }
    }
  } catch (error) {
    console.error("买入操作中发生错误:", error);
    return false;
  }
}

async function setFTokenAddress() {
  try {
    console.log(`开始设置FToken合约(${FoMoxAddress})的地址...`);
    
    const FoMox = await ethers.getContractAt("FoMox", FoMoxAddress) as FoMox;
    await FoMox.setFTokenAddress("0xE36CF4Aab15d778e6aAa44696369e29b77a84b2b");
    
    console.log("已设置FToken地址");
  } catch (error) {
    console.error("设置过程中发生错误:", error);
    throw error;
  }
}

async function setBlackList(address:string,flag:boolean) {
  try {
    console.log(`开始设置FoMox合约(${FoMoxAddress})的黑名单地址...`);
    const FoMox = await ethers.getContractAt("FoMox", FoMoxAddress) as FoMox;
     await FoMox.setBlockAddress(address, flag);
    console.log("已设置黑名单地址");
  } catch (error) {
    console.error("设置过程中发生错误:", error);
    throw error;
  }
}

async function getAmountsOut() {
  try {
    console.log(`开始获取FoMox合约(${FoMoxAddress})的价格...`);
    const FoMox = await ethers.getContractAt("FoMox", FoMoxAddress) as FoMox;
    const router = await ethers.getContractAt("IUniswapV2Router02", "0xD99D1c33F9fC3444f8101754aBC46c52416550D1") as IUniswapV2Router02;
    const usdtAddress = "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684"; // 测试网USDT地址
    const path = [usdtAddress, FoMoxAddress];
    
    const amountIn = ethers.parseUnits("18106473883045268", 0); // 1 USDT
    const amountsOut = await router.getAmountsOut(amountIn, path);
    
    console.log("估计输出量:", ethers.formatUnits(amountsOut[1], 18));
  } catch (error) {
    console.error("获取过程中发生错误:", error);
    throw error;
  }
}

async function simulatePancakeSwapSell() {
  try {
    console.log("开始模拟PancakeSwap卖出操作...");
    
    // 首先检查和设置交易对
    const pairReady = await setupAndCheckPair();
    if (!pairReady) {
      throw new Error("交易对设置失败，无法继续");
    }
    
    // 获取部署账户
    const [user] = await ethers.getSigners();
    console.log(`测试账户地址: ${user.address}`);
    
    // 配置需要的地址
    const usdtAddress = "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684"; 
    const routerAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; 
    const foMoxAddress = FoMoxAddress;
    
    // 获取合约实例
    const usdt = await ethers.getContractAt("IERC20", usdtAddress);
    const router = await ethers.getContractAt("IUniswapV2Router02", routerAddress) as IUniswapV2Router02;
    const foMox = await ethers.getContractAt("FoMox", foMoxAddress) as FoMox;
    
    // 检查FoMox余额
    const foMoxBalance = await foMox.balanceOf(user.address);
    console.log(`用户FoMox余额: ${ethers.formatUnits(foMoxBalance, 18)}`);
    
    if (foMoxBalance <= 0) {
      throw new Error("FoMox余额为零，无法进行卖出操作");
    }
    
    // 使用10%的余额进行测试卖出
    const amountToSell = ethers.parseEther("1181.83");
    console.log(`准备卖出 ${ethers.formatUnits(amountToSell, 18)} FoMox代币`);
    
    // 极大增加授权金额，确保不会因为授权不足而失败
    await foMox.connect(user).approve(routerAddress, amountToSell * BigInt(100));
    console.log("已批准路由器使用FoMox，授权金额为请求的100倍");
    
    // 设置交易参数
    const deadline = Math.floor(Date.now() / 1000) + 60 * 60; // 1小时过期时间
    const slippageTolerance = 3500; // 49%的滑点容忍度，接近任何价格
    
    // 设置交易路径 (卖出路径与买入相反)
    const path = [foMoxAddress, usdtAddress];
    console.log("交易路径:", path);
    
    try {
      console.log("尝试获取估计输出量...");
      const amountsOut = await router.getAmountsOut(amountToSell, path);
      console.log("估计获得USDT:", ethers.formatUnits(amountsOut[1], 18));
      
      const minAmountOut = amountsOut[1] * BigInt(10000 - slippageTolerance) / BigInt(10000);
      console.log("最小输出量:", ethers.formatUnits(minAmountOut, 18));
      
      // 记录卖出前USDT余额
      const initialUsdtBalance = await usdt.balanceOf(user.address);
      console.log(`卖出前USDT余额: ${ethers.formatUnits(initialUsdtBalance, 18)}`);
      
      console.log("尝试使用supportingFeeOnTransferTokens函数...");
      const tx = await router.connect(user).swapExactTokensForTokensSupportingFeeOnTransferTokens(
        amountToSell,
        minAmountOut, // 接受任何数量的输出
        path,
        user.address,
        deadline,
        { gasLimit: 3000000 } // 增加gas限制
      );
      
      console.log("交易已提交，等待确认...");
      await tx.wait();
      console.log(`交易已确认: ${tx.hash}`);
      
      // 检查交易后余额
      const finalFoMoxBalance = await foMox.balanceOf(user.address);
      const finalUsdtBalance = await usdt.balanceOf(user.address);
      
      console.log(`最终FoMox余额: ${ethers.formatUnits(finalFoMoxBalance, 18)}`);
      console.log(`最终USDT余额: ${ethers.formatUnits(finalUsdtBalance, 18)}`);
      console.log(`获得USDT: ${ethers.formatUnits(finalUsdtBalance - initialUsdtBalance, 18)}`);
      
      console.log("测试卖出操作完成");
      return true;
    } catch (error) {
      console.error("交换操作失败，详细错误:", error);
      return false;
    }
  } catch (error) {
    console.error("卖出操作中发生错误:", error);
    return false;
  }
}

main()
// upgradeFoMox(false)
// .then(async () => {
//   console.log("升级完成");
 
  //   simulatePancakeSwapBuy().then(async success => {
  //     if (success) {
  //       console.log("买入测试成功完成");
  //       await simulatePancakeSwapSell()
  //     } else {
  //       console.log("买入测试失败");
  //     }
  //     process.exit(0);    })
  // //   
 
// })
// .then(()=>{
  // simulatePancakeSwapSell().then(success => {
  //   if (success) {
  //     console.log("卖出测试成功完成");
  //   } else {
  //     console.log("卖出测试失败");
  //   }
  //   process.exit(0);
  // }).catch(error => {
  //   console.error("运行卖出测试时发生错误:", error);
  //   process.exit(1);
  // });
// }); // 传入true表示强制升级，注意风险
// getAmountsOut();
// getAmountsOut();


// setBlackList("0xa38433265062F1F73c0A90F2FEa408f2Efd1a569",true)

// setFTokenAddress();

// setWhiteAddress("0xD99D1c33F9fC3444f8101754aBC46c52416550D1",false)
// setWhiteAddress("0xa38433265062F1F73c0A90F2FEa408f2Efd1a569",false)

// 要测试卖出功能，可以取消下面这段代码的注释

