const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const XLTokenDAPP = await ethers.getContractFactory('XLTokenDAPP');
  const result = await upgrades.deployProxy(XLTokenDAPP, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const XLTokenDAPP = await ethers.getContractFactory("XLTokenDAPP");
  const upgraded = await upgrades.upgradeProxy("0x9346A72db85049d3e9f51B29374650742F370bE0", XLTokenDAPP);
  console.log(upgraded.address);
}
upgraded();