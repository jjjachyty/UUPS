const { ethers, upgrades } = require('hardhat');




describe('TEST', function () {
  it('deploys', async function () {

  //   const MyTokenV1 = await ethers.getContractFactory('TEST');
  // const result=  await upgrades.deployProxy(MyTokenV1, { kind: 'uups' });
  // console.log("address>>>>>>>>>>",result.address)


  const DOTTY = await ethers.getContractFactory("TEST");
  const upgraded = await upgrades.upgradeProxy("0x7fddd80da340e6348586b5237bDCe6ec135DB1b3", DOTTY);
  console.log(upgraded.address);

    });
});
