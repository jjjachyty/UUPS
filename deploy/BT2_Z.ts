// scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");

const BOX_ADDRESS="0x86E6103f3982610167754a5a0b092317BF2967A6"

async function create() {
  const Box = await ethers.getContractFactory("Z");
  const box = await upgrades.deployProxy(Box, ["0xfDb36E302FF8A379ED10566002F9AcE18fA576Ee"]);
  await box.waitForDeployment();
  console.log("Box deployed to:", await box.getAddress());
}

async function update() {
  const BoxV2 = await ethers.getContractFactory("Z");
  const box = await upgrades.upgradeProxy(BOX_ADDRESS, BoxV2);
  console.log("Box upgraded");
}

create();