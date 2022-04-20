const { ethers, upgrades } = require('hardhat');




describe('TEST', function () {
  it('deploys', async function () {

  // const MyTokenV1 = await ethers.getContractFactory('TEST');
  // const result=  await upgrades.deployProxy(MyTokenV1, { kind: 'uups' });
  // console.log("address>>>>>>>>>>",result.address)


  const DOTTY = await ethers.getContractFactory("TEST");
  const upgraded = await upgrades.upgradeProxy("0x4D77F4e503F516c7f409F60457CA93A44Ba43E1e", DOTTY);
  console.log(upgraded.address);

    });
});
