const { ethers, upgrades } = require("hardhat");

async function test_deployed() {
  const SDZZToken = await ethers.getContractFactory('SDZZIDO');
  const result = await upgrades.deployProxy(SDZZToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function test_upgraded() {
  // Upgrading
  const SDZZToken = await ethers.getContractFactory("SDZZIDO");
  const upgraded = await upgrades.upgradeProxy("0x38101e89f0bea379FDC4BfCD4B4E0C5325d935B3", SDZZToken);
  console.log(upgraded.address);
}

async function prd_deployed() {
  const SDZZToken = await ethers.getContractFactory('SDZZIDO');
  const result = await upgrades.deployProxy(SDZZToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function prd_upgraded() {

  // Upgrading
  const SDZZToken = await ethers.getContractFactory("SDZZIDO");
  const upgraded = await upgrades.upgradeProxy("0x8441966dBa2e38DE9E2be5C334b55DaE0043db2E", SDZZToken);
  console.log(upgraded.address);
}
prd_upgraded();