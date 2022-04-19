const { ethers, upgrades } = require('hardhat');




describe('TEST', function () {
  it('deploys', async function () {

  //   const MyTokenV1 = await ethers.getContractFactory('TEST');
  // const result=  await upgrades.deployProxy(MyTokenV1, { kind: 'uups' });
  // console.log("address>>>>>>>>>>",result.address)


  const DOTTY = await ethers.getContractFactory("TEST");
  const upgraded = await upgrades.upgradeProxy("0x26DCE78e28b7251278f30387B6686cec7D5850F2", DOTTY);
  console.log(upgraded.address);

    });
});
