const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const XLTokenDAPP = await ethers.getContractFactory('XLTokenDAPP');
  const result = await upgrades.deployProxy(XLTokenDAPP, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const XLTokenDAPP = await ethers.getContractFactory("XLTokenDAPP");
  const upgraded = await upgrades.upgradeProxy("0x7E733A8AE6891Db01102D0688001331762EF1a58", XLTokenDAPP);
  console.log(upgraded.address);
}
upgraded();