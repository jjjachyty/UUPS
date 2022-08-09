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
  const upgraded = await upgrades.upgradeProxy("0x1173ae74066953db24Cfd2857a124e4daffF285A", SDZZToken);
  console.log(upgraded.address);
}

async function nft_deployed() {
  const SDZZToken = await ethers.getContractFactory('SDZZNFT');
  const result = await upgrades.deployProxy(SDZZToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function nft_upgraded() {

  // Upgrading
  const SDZZToken = await ethers.getContractFactory("SDZZNFT");
  const upgraded = await upgrades.upgradeProxy("0xEDCaD539De907223D10E3c360263875499dBce27", SDZZToken);
  console.log(upgraded.address);
}
nft_deployed();