const { ethers, upgrades } = require("hardhat");

async function deployed() {
  const XLToken = await ethers.getContractFactory('XLToken');
  const result = await upgrades.deployProxy(XLToken, { kind: 'uups' });
  console.log("address>>>>>>>>>>", result.address)

}

async function upgraded() {

  // Upgrading
  const XLToken = await ethers.getContractFactory("XLToken");
  const upgraded = await upgrades.upgradeProxy("0xF3953F7fd3618B0cD0046C69A8D1FC8987510749", XLToken);
  console.log(upgraded.address);
}
upgraded();