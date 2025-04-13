import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { Contract } from "ethers";
import { FoMox, MockERC20,MockUniswapV2Factory } from "../typechain-types";
const ProxyAddress = "0x077497eea54d94A8Da57b48c79c275F9dd71A6b9"; // MoPool 代理合约地址

describe("FoMox", function () {
  // 合约实例
  let fomox: FoMox;
  let mockUSDT: MockERC20;
  let mockRouter: Contract;
  let mockPair: Contract;
  let mockFoPool: Contract;
  let mockMoPool: Contract;
  let mockFToken: Contract;
  let mockFactory: MockUniswapV2Factory;
  
  // 签名者
  let owner: any;
  let user1: any;
  let user2: any;
  let tech: any;
  let eco: any;
  let foPoolReward: any;
  let communityReward: any;
  
  // 签名者地址
  let ownerAddress: string;
  let user1Address: string;
  let user2Address: string;
  let techAddress: string;
  let ecoAddress: string;
  let foPoolRewardAddress: string;
  let communityRewardAddress: string;
  
  // 常量
  const INITIAL_USDT_SUPPLY = ethers.parseEther("100000000");
  const INITIAL_LIQUIDITY = ethers.parseEther("100000000");
  const INITIAL_USDT = ethers.parseEther("10000");
  const BUY_AMOUNT = ethers.parseEther("100");
  const SELL_AMOUNT = ethers.parseEther("50");
  
  beforeEach(async function () {
    // 获取签名者
    [owner, user1, user2, tech, eco, foPoolReward, communityReward] = await ethers.getSigners();
      fomox = await ethers.getContractAt("FoMox", "0x077497eea54d94A8Da57b48c79c275F9dd71A6b9") as unknown as FoMox;
  });
  
  describe("初始化", function () {
    it("应该正确购买", async function () {
      expect(await fomox.name()).to.equal("FoMox");
       
         try {
          console.log("开始模拟PancakeSwap买入操作...");
          
          // 获取部署账户
          const [user] = await ethers.getSigners();
          console.log(`测试账户地址: ${user.address}`);
          
          // 配置需要的地址
          const usdtAddress = "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684"; // 测试网USDT地址
          const routerAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; // 测试网路由器地址
          const foMoxAddress = ProxyAddress;
          
          // 获取合约实例
          const usdt = await ethers.getContractAt("IERC20", usdtAddress);
          const router = await ethers.getContractAt("IUniswapV2Router02", routerAddress);
          const foMox = await ethers.getContractAt("FoMox", foMoxAddress) as FoMox;
          
          // 检查用户USDT余额
          const userUsdtBalance = await usdt.balanceOf(user.address);
          console.log(`用户USDT余额: ${ethers.formatUnits(userUsdtBalance, 18)}`);
          
          if (userUsdtBalance === BigInt(0)) {
            console.log("用户没有USDT，尝试从部署者获取一些USDT...");
            // 如果是测试网，我们可以从部署者转移一些USDT到用户
            throw new Error("用户没有USDT");
          }
          
          // 获取当前FoMox余额
          const initialFoMoxBalance = await foMox.balanceOf(user.address);
          console.log(`初始FoMox余额: ${ethers.formatUnits(initialFoMoxBalance, 18)}`);
          
          // 批准路由器使用USDT
          const amountToSpend = ethers.parseUnits("0.001", 18); // 0.01 USDT
          console.log(`准备用 ${ethers.formatUnits(amountToSpend, 18)} USDT 购买FoMox`);
          
          await usdt.connect(user).approve(routerAddress, amountToSpend);
          console.log("已批准路由器使用USDT");
          
          // 设置交易参数
          const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20分钟后过期
          const slippageTolerance = 1000; // 5%的滑点容忍度
          
          // 获取预估输出
          const path = [usdtAddress, foMoxAddress];
          const amountsOut = await router.getAmountsOut(amountToSpend, path);
          const minAmountOut = amountsOut[1] * BigInt(10000 - slippageTolerance) / BigInt(10000);
          
          console.log(`预计得到至少 ${ethers.formatUnits(minAmountOut, 18)} FoMox`);
          throw new Error("用户没有USDT");
          // 执行swap操作
          console.log("执行交易...");
          const tx = await router.connect(user).swapExactTokensForTokens(
            amountToSpend,
            minAmountOut,
            path,
            user.address,
            deadline
          );
          
          await tx.wait();
          console.log(`交易已确认: ${tx.hash}`);
          
          // 检查交易后FoMox余额
          const finalFoMoxBalance = await foMox.balanceOf(user.address);
          console.log(`最终FoMox余额: ${ethers.formatUnits(finalFoMoxBalance, 18)}`);
          console.log(`获得FoMox: ${ethers.formatUnits(finalFoMoxBalance - (initialFoMoxBalance), 18)}`);
          
          // 检查用户信息
          const userInfo = await foMox.userInfo(user.address);
          console.log(`用户持仓信息:`);
          console.log(`- 上次购买时间: ${new Date(Number(userInfo.lastBuyTimestamp * BigInt(1000))).toLocaleString()}`);
          console.log(`- 总购买金额: ${ethers.formatUnits(userInfo.totalBought, 18)} USDT`);
          
          console.log("测试买入操作完成");
        } catch (error) {
          console.error("买入操作中发生错误:", error);
        }
      
    });
     
  });
   
});
