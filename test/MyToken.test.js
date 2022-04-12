const { ethers, upgrades } = require('hardhat');




describe('AAA', function () {
  it('deploys', async function () {

    const MyTokenV1 = await ethers.getContractFactory('AAA');
  const result=  await upgrades.deployProxy(MyTokenV1, { kind: 'uups' });
  console.log("address>>>>>>>>>>",result.address)


  // const AAA = await ethers.getContractFactory("AAA");
  // const upgraded = await upgrades.upgradeProxy("0x3d6bBc8906075b92AE4CC3855d773A79F8d624cf", AAA);
  // console.log(upgraded.address);

    });
});
