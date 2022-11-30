const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const DAPP = await ethers.getContractFactory('PMM108Distribution');
  const result = await upgrades.deployProxy(DAPP, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const DAPP = await ethers.getContractFactory("PMM108Distribution");
  const upgraded = await upgrades.upgradeProxy("0xBe74A485158488Fbfa68881bde59cC45cf78727d", DAPP);
  console.log(upgraded.address);
}

async function upgraded_prd() {

  // Upgrading
  const DAPP = await ethers.getContractFactory("PMM108Distribution");
  const upgraded = await upgrades.upgradeProxy("0x451BbA95B305C20DEF416111A008e032432325c2", DAPP);
  console.log(upgraded.address);
}

upgraded_prd();

