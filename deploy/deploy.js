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
  const upgraded = await upgrades.upgradeProxy("0x6897a0B8Bf35E138d4e3537A08beE92Fe120bf49", MyTokenV2);
  console.log(upgraded.address);
}
upgraded();