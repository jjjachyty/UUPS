const { ethers, upgrades } = require('hardhat');




describe('DOTTY', function () {
  it('deploys', async function () {

    const DOTTY = await ethers.getContractFactory('DOTTY');
  const result=  await upgrades.deployProxy(DOTTY, { kind: 'uups' });
  console.log("address>>>>>>>>>>",result.address)


  // const DOTTY = await ethers.getContractFactory("DOTTY");
  // const upgraded = await upgrades.upgradeProxy("0x26DCE78e28b7251278f30387B6686cec7D5850F2", DOTTY);
  // console.log(upgraded.address);

    });
});
