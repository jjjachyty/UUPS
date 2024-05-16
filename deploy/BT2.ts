// scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
import "@nomicfoundation/hardhat-verify";
import "@openzeppelin/hardhat-upgrades";

const BOX_ADDRESS="0x0280F73253a643A1CA1b89E3f357e320A326651e"

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