const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const NBBFun = await ethers.getContractFactory('NBBFun');
  const result = await upgrades.deployProxy(NBBFun, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

// async function forceImport() {

//   // Upgrading
//   const NBBFun = await ethers.getContractFactory("NBBFun");
//   const upgraded = await upgrades.forceImport("0x5F7Fba78061c84bC356E83C6a462E9329B5fFD42", NBBFun);
//   console.log(upgraded.address);
// }

// async function upgraded() {

//   // Upgrading
//   const NBBFun = await ethers.getContractFactory("NBBFun");
//   const upgraded = await upgrades.upgradeProxy("0xC733Bfe7F704dA3298821F8584681B8bB2979a7d", NBBFun);
//   console.log(upgraded.address);
// }

async function upgraded() {
  // Upgrading
  const NBBFun = await ethers.getContractFactory("NBBFun");
  const upgraded = await upgrades.upgradeProxy("0x4Db125D0082062D7569BEA78E1BaC1d4b122008C", NBBFun);
  console.log(upgraded.address);
}

upgraded()