const { ethers, upgrades } = require("hardhat");

async function deployed_test() {
  const CTO = await ethers.getContractFactory('CTO');
  const result = await upgrades.deployProxy(CTO, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded_test() {

  // Upgrading
  const DAPP = await ethers.getContractFactory("CTO");
  const upgraded = await upgrades.upgradeProxy("0xEd4c5AFaea627776889f9471042b972f80F84D53", DAPP);
  console.log(upgraded.address);
}

deployed_test()