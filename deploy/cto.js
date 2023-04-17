const { ethers, upgrades } = require("hardhat");

async function deployed_test() {
  const CTO = await ethers.getContractFactory('CTO');
  const result = await upgrades.deployProxy(CTO, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded_test() {

  // Upgrading
  const DAPP = await ethers.getContractFactory("CTO");
  const upgraded = await upgrades.upgradeProxy("0xaDE76c8Bbc405c1fF367e10C786c81EeF0357454", DAPP);
  console.log(upgraded.address);
}
async function upgraded_CTOCatch_prd() {

  // Upgrading
  const DAPP = await ethers.getContractFactory("CTOCatch");
  const upgraded = await upgrades.upgradeProxy("0x6Bf5709FE937612260A232C621902bc00225b1Fd", DAPP);
  console.log(upgraded.address);
}
