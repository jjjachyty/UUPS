const { ethers, upgrades } = require("hardhat");

async function deployed() {
  // Deploying
  const Box = await ethers.getContractFactory("Box");
  const instance = await upgrades.deployProxy(Box, [42]);
  await instance.deployed();
}

async function upgraded(){
    
  // Upgrading
  const MyTokenV2 = await ethers.getContractFactory("MyTokenV2");
  const upgraded = await upgrades.upgradeProxy("0x005bc061B0B3Cf75FEA42a4F154dd22909b88E5e", MyTokenV2);
  console.log(upgraded.address);
}
upgraded();