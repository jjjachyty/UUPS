const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const XLToken = await ethers.getContractFactory('XLToken');
  const result = await upgrades.deployProxy(XLToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const XLToken = await ethers.getContractFactory("XLToken");
  const upgraded = await upgrades.upgradeProxy("0xC255Fe6ee698D39c9c2749df9e15CbaB333Ab0aF", XLToken);
  console.log(upgraded.address);
}
upgraded();