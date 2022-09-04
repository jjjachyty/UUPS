const { ethers, upgrades } = require("hardhat");

// async function transferUSDT() {
//   const [deployer] = await ethers.getSigners();
//   const NBBToken = await ethers.getContractFactory('NBBToken');
//   const NBBCatch = await ethers.getContractFactory('NBBCatch');
//   try {
//   const result = await NBBCatch.deploy("0xfF73db72a512DB450E7D300312D3867A0B8A017f")
//   console.log(result)
//   await NBBToken.connect(deployer).setTransUAddress(result.address)
//   const transferAddress = await  NBBToken.transferAddress()
//   console.log("transferAddress",transferAddress)
//   const transferResult =  await NBBCatch.transferUSDT("0x8bF813F675bDE7b9A05244eaBeE31Ca9a3AB1a0D",deployer.address,ethers.utils.parseEther("1"))
//   console.log("transferAddress",transferResult)
//   } catch (error) {
//     console.error(error)
//   }
// }
//0x86d3599a64fDED05C3CAB92D863D1B80272B843E
transferUSDT();