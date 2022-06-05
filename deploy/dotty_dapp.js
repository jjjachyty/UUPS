const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const DAPP = await ethers.getContractFactory('DAPP');
  const result = await upgrades.deployProxy(DAPP, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

// async function upgraded() {

//   // Upgrading
//   const DAPP = await ethers.getContractFactory("DAPP");
//   const upgraded = await upgrades.upgradeProxy("0x43399a70Ff091F59732e8D54c93AF35DeCD3818C", DAPP);
//   console.log(upgraded.address);
// }
deployed();