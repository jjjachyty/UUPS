const { ethers, upgrades } = require('hardhat');




describe('DOTTY', function () {
  it('deploys', async function () {

  //   const DOTTY = await ethers.getContractFactory('DOTTY');
  // const result=  await upgrades.deployProxy(DOTTY, { kind: 'uups' });
  // console.log("address>>>>>>>>>>",result.address)


  const DOTTY = await ethers.getContractFactory("DOTTY");
  const upgraded = await upgrades.upgradeProxy("0xBf70979848A34b3205961d3469f68e5B68834F3f", DOTTY);
  console.log(upgraded.address);

    });
});
