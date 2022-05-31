const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const XLTokenDAPP = await ethers.getContractFactory('XLTokenDAPP');
  const result = await upgrades.deployProxy(XLTokenDAPP, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const XLTokenDAPP = await ethers.getContractFactory("XLTokenDAPP");
  const upgraded = await upgrades.upgradeProxy("0x43399a70Ff091F59732e8D54c93AF35DeCD3818C", XLTokenDAPP);
  console.log(upgraded.address);
}
upgraded();