const { ethers, upgrades } = require('hardhat');




describe('DOTTY', function () {
  it('deploys', async function () {

  //   const MyTokenV1 = await ethers.getContractFactory('DOTTY');
  // const result=  await upgrades.deployProxy(MyTokenV1, { kind: 'uups' });
  // console.log("address>>>>>>>>>>",result.address)


  const DOTTY = await ethers.getContractFactory("DOTTY");
  const upgraded = await upgrades.upgradeProxy("0x71571B23F4882430E8f5BdAa07d2a2dFecaf689d", DOTTY);
  console.log(upgraded.address);

    });
});
