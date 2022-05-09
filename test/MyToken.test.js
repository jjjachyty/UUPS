const { ethers, upgrades } = require('hardhat');




describe('DOTTY', function () {
  it('deploys', async function () {

  //   const DOTTY = await ethers.getContractFactory('DOTTY');
  // const result=  await upgrades.deployProxy(DOTTY, { kind: 'uups' });
  // console.log("address>>>>>>>>>>",result.address)


  const DOTTY = await ethers.getContractFactory("DOTTY");
  const upgraded = await upgrades.upgradeProxy("0x914e7da57090d9A74338D915408676DD63526C33", DOTTY);
  console.log(upgraded.address);

    });
});
