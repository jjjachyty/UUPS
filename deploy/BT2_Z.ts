// scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");

const BOX_ADDRESS="0xb315fA7699013baE4C87ED7a7D9ea9Eb80f41Cf8"

async function create() {
  const Box = await ethers.getContractFactory("Z");
  const box = await upgrades.deployProxy(Box, ["0x9F90C5cd1418c4D2Ab733d7335498149C5b14169"]);
  await box.waitForDeployment();
  console.log("Box deployed to:", await box.getAddress());
}

async function update() {
  const BoxV2 = await ethers.getContractFactory("Z");
  const box = await upgrades.upgradeProxy(BOX_ADDRESS, BoxV2);
  console.log("Box upgraded");
}

create();