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
  const upgraded = await upgrades.upgradeProxy("0xbC10307c9472410AF315000C612952928ACDaAc0", SDZZToken);
  console.log(upgraded.address);
}

async function nft_deployed() {
  const SDZZToken = await ethers.getContractFactory('SDZZNFT');
  const result = await upgrades.deployProxy(SDZZToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

prd_upgraded();