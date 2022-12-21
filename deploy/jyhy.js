const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const DAPP = await ethers.getContractFactory('JYHY');
  const result = await upgrades.deployProxy(DAPP, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const DAPP = await ethers.getContractFactory("JYHY");
  const upgraded = await upgrades.upgradeProxy("0xf489a6CCb0267A0B4675Ad01BEAfbB471813030B", DAPP);
  console.log(upgraded.address);
}
deployed();