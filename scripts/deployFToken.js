const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("开始部署FToken合约...");

  // 获取部署者账户
  const [deployer] = await ethers.getSigners();
  console.log("部署账户:", deployer.address);

  // 部署F代币合约
  const FToken = await ethers.getContractFactory("FToken");
  console.log("正在部署FToken代理合约...");
  
  // 初始供应量: 1000万个F代币
  const initialSupply = ethers.utils.parseEther("10000000");
  
  // 使用UUPS代理模式部署
  const fToken = await upgrades.deployProxy(FToken, [initialSupply], { 
    initializer: 'initialize',
    kind: 'uups'
  });
  
  await fToken.deployed();
  console.log("FToken代理合约已部署到:", fToken.address);
  console.log("FToken实现合约地址:", await upgrades.erc1967.getImplementationAddress(fToken.address));
  
  // 这时需要设置FoMox合约地址，但需要先获取FoMox地址后再手动设置
  console.log("部署完成，请使用以下命令将FoMox地址设置到F代币合约中:");
  console.log(`npx hardhat --network <网络> execute-tx --to ${fToken.address} --fn "setFoMoxAddress" --args "<FoMox合约地址>"`);
  
  // 同样需要在FoMox合约中设置F代币地址
  console.log("同时，请使用以下命令将F代币地址设置到FoMox合约中:");
  console.log(`npx hardhat --network <网络> execute-tx --to <FoMox合约地址> --fn "setFTokenAddress" --args "${fToken.address}"`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
