const { ethers, upgrades } = require('hardhat');




describe('MyToken', function () {
  it('deploys', async function () {

    const MyTokenV1 = await ethers.getContractFactory('AAA');
  const result=  await upgrades.deployProxy(MyTokenV1, { kind: 'uups' });
  console.log("address>>>>>>>>>>",result.address)
  });
});
