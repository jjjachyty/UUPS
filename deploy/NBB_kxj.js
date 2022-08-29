const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const NBBToken = await ethers.getContractFactory('NBBToken');
  const result = await upgrades.deployProxy(NBBToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}


deployed()