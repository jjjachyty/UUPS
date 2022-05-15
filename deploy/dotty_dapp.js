const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const DAPP = await ethers.getContractFactory('DAPP');
  const result = await upgrades.deployProxy(DAPP, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const DAPP = await ethers.getContractFactory("DAPP");
  const upgraded = await upgrades.upgradeProxy("0xF42A11B5d008635346FB0828531C72482d4a8e92", DAPP);
  console.log(upgraded.address);
}
upgraded();