import { ethers } from "hardhat";
import { FoMox, MoPool } from "../typechain-types/contracts";
import { FoPool, FToken } from "../typechain-types";


const FoMoxAddress = "0xc48198310dba32ffa09CA13fE7d984227072b11b";  //  // 测试网FoMox地址
const FTokenAddress = "0xE36CF4Aab15d778e6aAa44696369e29b77a84b2b"
const FoPoolAddress = "0x2D9be4288334B8E0690b051129fdcca7736695c4"; // 测试网FoPool地址
const MopolAddress = "0x5E231abD8d6DEA1cFbf59399eb6e3B2B306e586f"; // 测试网MoPool地址

async function setFoMoxAddress() {
   var Mopol =  await ethers.getContractAt("MoPool", MopolAddress) as MoPool;
    const tx = await Mopol.setFomoxAddress(FoMoxAddress);
    var FToken = await ethers.getContractAt("FToken", FTokenAddress) as FToken;
    const tx2 = await FToken.setFoMoxAddress(FoMoxAddress);
    var FoPool = await ethers.getContractAt("FoPool", FoPoolAddress) as FoPool;
    const tx3 = await FoPool.setFomoxAddress(FoMoxAddress);
    console.log("已设置FoMox地址");
}

async function initFoMox() {
    var FoMox = await ethers.getContractAt("FoMox", FoMoxAddress) as FoMox;
    const tx = await FoMox.setPoolContracts(FoPoolAddress, MopolAddress);
    const tx2 = await FoMox.setFTokenAddress(FTokenAddress);
    console.log("初始化FoMox交易哈希:", tx.hash);
}


initFoMox()