const { ethers, upgrades } = require("hardhat");

async function test_deployed() {
  const SDZZToken = await ethers.getContractFactory('SDZZNFT');
  const result = await upgrades.deployProxy(SDZZToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function test_upgraded() {

  // Upgrading
  const SDZZToken = await ethers.getContractFactory("SDZZNFT");
  const upgraded = await upgrades.upgradeProxy("0xE12beab8eeFb79BDC00d490ea1E1F4F61C913C0A", SDZZToken);
  console.log(upgraded.address);
}

async function prd_deployed() {
  const SDZZToken = await ethers.getContractFactory('SDZZNFT');
  const result = await upgrades.deployProxy(SDZZToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function prd_upgraded() {

  // Upgrading
  const SDZZToken = await ethers.getContractFactory("SDZZNFT");
  const upgraded = await upgrades.upgradeProxy("0xE12beab8eeFb79BDC00d490ea1E1F4F61C913C0A", SDZZToken);
  console.log(upgraded.address);
}
prd_deployed();