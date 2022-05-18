const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const DAPP = await ethers.getContractFactory('DAPP');
  const result = await upgrades.deployProxy(DAPP, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const DAPP = await ethers.getContractFactory("DAPP");
  const upgraded = await upgrades.upgradeProxy("0x253e249A734cabA69eB1fe59B0Ad5337599Deddc", DAPP);
  console.log(upgraded.address);
}
upgraded();