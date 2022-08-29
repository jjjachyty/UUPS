const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const NBBV2Token = await ethers.getContractFactory('NBBV2Token');
  const result = await upgrades.deployProxy(NBBV2Token, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}



async function upgraded() {

  // Upgrading
  const NBBV2Token = await ethers.getContractFactory("NBBV2Token");
  const upgraded = await upgrades.upgradeProxy("0x3F107b36D4Aaf3BB4c3EA2C2E55d33d2C82E7F5E", NBBV2Token);
  console.log(upgraded.address);
}


deployed();