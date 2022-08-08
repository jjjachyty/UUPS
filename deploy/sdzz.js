const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const SDZZToken = await ethers.getContractFactory('SDZZToken');
  const result = await upgrades.deployProxy(SDZZToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const SDZZToken = await ethers.getContractFactory("SDZZToken");
  const upgraded = await upgrades.upgradeProxy("0xEDCaD539De907223D10E3c360263875499dBce27", SDZZToken);
  console.log(upgraded.address);
}
upgraded();