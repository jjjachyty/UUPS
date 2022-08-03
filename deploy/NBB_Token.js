const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const NBBToken = await ethers.getContractFactory('NBBToken');
  const result = await upgrades.deployProxy(NBBToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const NBBToken = await ethers.getContractFactory("NBBToken");
  const upgraded = await upgrades.upgradeProxy("0x3F107b36D4Aaf3BB4c3EA2C2E55d33d2C82E7F5E", NBBToken);
  console.log(upgraded.address);
}
upgraded();