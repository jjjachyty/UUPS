const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const XLTokenDAPP = await ethers.getContractFactory('XLTokenDAPP');
  const result = await upgrades.deployProxy(XLTokenDAPP, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const XLTokenDAPP = await ethers.getContractFactory("XLTokenDAPP");
  const upgraded = await upgrades.upgradeProxy("0x7668c3Df6c9454932Cc6f0a7ac0f4d23058e2F33", XLTokenDAPP);
  console.log(upgraded.address);
}
upgraded();