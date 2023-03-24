const { ethers, upgrades } = require("hardhat");

async function deployed_test() {
  const DAPP = await ethers.getContractFactory('ALEO');
  const result = await upgrades.deployProxy(DAPP, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded_test() {

  // Upgrading
  const DAPP = await ethers.getContractFactory("ALEO");
  const upgraded = await upgrades.upgradeProxy("0xd319A39FAD5D2f287fd38A6bbF59f374dFe9952a", DAPP);
  console.log(upgraded.address);
}
upgraded_test();