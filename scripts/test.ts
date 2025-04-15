import { ethers } from "hardhat";
import { FoMox, MoPool } from "../typechain-types/contracts";
import { FoPool, FToken } from "../typechain-types";


 
export const FoMoxAddress = "0xDA3f984984a78c5cCa44e02eA34d94312108aBEE";  //FoMox地址
export const FTokenAddress = "0xED5Ddc075B1103b9a39dac115Afd974c95702116" //FToken地址
export const FoPoolAddress = "0x9B84736679cFD7E64c96e2d58F4a8bb698a788F6"; //FoPool地址
export const MoPoolAddress = "0x1cBa4242cAE8e8A9EC55485da095286E628889B4"; //MoPool地址

export const usdtAddress = "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684"; // 或其他指定地址
export const routerAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; // 或其他指定地址
 
export const techAddress = "0xdCF979Ff64f3Beb99e6600b24c3FC907011A678A"; // 技术维护地址
export const ecoAddress = "0xdCF979Ff64f3Beb99e6600b24c3FC907011A678A"; // 生态地址
export const foPoolRewardAddress = "0xdCF979Ff64f3Beb99e6600b24c3FC907011A678A"; // Fo池分红地址
export const communityRewardAddress = "0xdCF979Ff64f3Beb99e6600b24c3FC907011A678A"; // 社区奖励地址



// export const FoMoxAddress = "0xF078Dcd093e3aDC58c7F89C5cfAacd5EA97B6a55";  //FoMox地址
// export const FTokenAddress = "0xD5D63124184d6f513A4Af68dF05C9008d558e016" //FToken地址
// export const FoPoolAddress = "0x66cCE7C433F4029Ed478941330B9a2A63BFbfCf0"; //FoPool地址
// export const MoPoolAddress = "0xCe49310d701C74CEf6116f6103BFE6B8F47F7b62"; //MoPool地址

// export const usdtAddress = "0x55d398326f99059fF775485246999027B3197955"; // 或其他指定地址
// export const routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // 或其他指定地址
// export const uniswapPairAddress = "0x50991E10dC1BFEC71822A9C656133e31e60797F8"; // 或其他指定地址

// export const techAddress = "0xdCF979Ff64f3Beb99e6600b24c3FC907011A678A"; // 技术维护地址
// export const ecoAddress = "0xdCF979Ff64f3Beb99e6600b24c3FC907011A678A"; // 生态地址
// export const foPoolRewardAddress = "0xdCF979Ff64f3Beb99e6600b24c3FC907011A678A"; // Fo池分红地址
// export const communityRewardAddress = "0xdCF979Ff64f3Beb99e6600b24c3FC907011A678A"; // 社区奖励地址




async function setFoMoxAddress() {
//    var Mopol =  await ethers.getContractAt("MoPool", MoPoolAddress) as MoPool;
    // const tx = await Mopol.setFomoxAddress(FoMoxAddress);
    var FToken = await ethers.getContractAt("FToken", FTokenAddress) as FToken;
    const tx2 = await FToken.setFoMoxAddress(FoMoxAddress);
    // var FoPool = await ethers.getContractAt("FoPool", FoPoolAddress) as FoPool;
    // const tx3 = await FoPool.setFomoxAddress(FoMoxAddress);
     console.log("已设置FoMox地址");
}

async function initFoMox() {
    var FoMox = await ethers.getContractAt("FoMox", FoMoxAddress) as FoMox;
    const tx = await FoMox.setPoolContracts(FoPoolAddress, MoPoolAddress);
    const tx2 = await FoMox.setFTokenAddress(FTokenAddress);
    console.log("初始化FoMox交易哈希:", tx.hash);
}

 
initFoMox()
 