const { ethers, upgrades } = require('hardhat');




describe('TEST', function () {
  it('deploys', async function () {

  //   const MyTokenV1 = await ethers.getContractFactory('TEST');
  // const result=  await upgrades.deployProxy(MyTokenV1, { kind: 'uups' });
  // console.log("address>>>>>>>>>>",result.address)


  const DOTTY = await ethers.getContractFactory("TEST");
<<<<<<< HEAD
  const upgraded = await upgrades.upgradeProxy("0x47aDf62802080515aE8348D15dA93060645711A9", DOTTY);
=======
  const upgraded = await upgrades.upgradeProxy("0x26DCE78e28b7251278f30387B6686cec7D5850F2", DOTTY);
>>>>>>> 8ea76e217f179cd30444b08b13534fa94c59a2ef
  console.log(upgraded.address);

    });
});
