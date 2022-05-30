const { ethers, upgrades } = require('hardhat');




describe('DOTTY', function () {
  it('deploys', async function () {

    //   const DOTTYTEST = await ethers.getContractFactory('DOTTYTEST');
    // const result=  await upgrades.deployProxy(DOTTYTEST, { kind: 'uups' });
    // console.log("address>>>>>>>>>>",result.address)


    // const DOTTYTEST = await ethers.getContractFactory("DOTTYTEST");
    // const upgraded = await upgrades.upgradeProxy("0x52b0B3BD1538f36771463F627Fc4f4694cF77a7d", DOTTYTEST);
    // console.log(upgraded.address);

    // const DAPP = await ethers.getContractFactory('DAPP');
    // const result = await upgrades.deployProxy(DAPP, { kind: 'uups' });
    // console.log("address>>>>DAPP>>>>>>", result.address)

    // const DAPP = await ethers.getContractFactory("DAPP");
    // const upgraded = await upgrades.upgradeProxy("0x33eBf00e7E2b6c5B5768fBa452D6967E339db307", DAPP);
    // console.log(upgraded.address);

    
  });
});
//////////////////////////////////////////////////PRD
describe('DOTTY', function () {
  it('deploys', async function () {

    // const XLToken = await ethers.getContractFactory('XLToken');
    // const result=  await upgrades.deployProxy(XLToken, { kind: 'uups' });
    // console.log("address>>>>>>>>>>",result.address)


    const XLTokenDAPP = await ethers.getContractFactory("XLTokenDAPP");
    const upgraded = await upgrades.upgradeProxy("0x5A87A92420a0Bd25604a4Ae3f3D592af84f29Cd0", XLTokenDAPP);
    console.log(upgraded.address);

    // const DAPP = await ethers.getContractFactory('DAPP');
    // const result = await upgrades.deployProxy(DAPP, { kind: 'uups' });
    // console.log("address>>>>DAPP>>>>>>", result.address)

    // const DAPP = await ethers.getContractFactory("DAPP");
    // const upgraded = await upgrades.upgradeProxy("0x33eBf00e7E2b6c5B5768fBa452D6967E339db307", DAPP);
    // console.log(upgraded.address);

    
  });
});
