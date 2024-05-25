// scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
import "@nomicfoundation/hardhat-verify";
import "@openzeppelin/hardhat-upgrades";

const BOX_ADDRESS="0x9F90C5cd1418c4D2Ab733d7335498149C5b14169"

async function create() {
  const Box = await ethers.getContractFactory("BT2");
  const box = await upgrades.deployProxy(Box, []);
  await box.waitForDeployment();
  console.log("Box deployed to:", await box.getAddress());
}

async function update() {
  const BoxV2 = await ethers.getContractFactory("BT2");
  const box = await upgrades.upgradeProxy(BOX_ADDRESS, BoxV2);
  console.log("Box upgraded");
}

create();