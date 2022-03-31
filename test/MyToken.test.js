const { ethers, upgrades } = require('hardhat');




describe('MyToken', function () {
  it('deploys', async function () {

  //   const MyTokenV1 = await ethers.getContractFactory('AAA');
  // const result=  await upgrades.deployProxy(MyTokenV1, { kind: 'uups' });
  // console.log("address>>>>>>>>>>",result.address)
  // });

  const AAA = await ethers.getContractFactory("AAA");
  const upgraded = await upgrades.upgradeProxy("0x6D23c90EC903C77098FDCf687Cfd470E5A2b037d", AAA);
  console.log(upgraded.address);

   });
});
