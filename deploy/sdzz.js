const { ethers, upgrades } = require("hardhat");

async function test_deployed() {
  const SDZZToken = await ethers.getContractFactory('SDZZToken');
  const result = await upgrades.deployProxy(SDZZToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function test_upgraded() {

  // Upgrading
  const SDZZToken = await ethers.getContractFactory("SDZZToken");
  const upgraded = await upgrades.upgradeProxy("0xEDCaD539De907223D10E3c360263875499dBce27", SDZZToken);
  console.log(upgraded.address);
}

async function prd_deployed() {
  const SDZZToken = await ethers.getContractFactory('SDZZToken');
  const result = await upgrades.deployProxy(SDZZToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function prd_upgraded() {

  // Upgrading
  const SDZZToken = await ethers.getContractFactory("SDZZToken");
  const upgraded = await upgrades.upgradeProxy("0xB8333E196F58b3fE54d427028cAb2a14c82C4710", SDZZToken);
  console.log(upgraded.address);
}


prd_upgraded();