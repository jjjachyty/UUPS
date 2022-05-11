const { ethers, upgrades } = require('hardhat');




describe('DOTTY', function () {
  it('deploys', async function () {

    //   const DOTTY = await ethers.getContractFactory('DOTTY');
    // const result=  await upgrades.deployProxy(DOTTY, { kind: 'uups' });
    // console.log("address>>>>>>>>>>",result.address)


    // const DOTTY = await ethers.getContractFactory("DOTTY");
    // const upgraded = await upgrades.upgradeProxy("0xBf70979848A34b3205961d3469f68e5B68834F3f", DOTTY);
    // console.log(upgraded.address);

    // const DAPP = await ethers.getContractFactory('DAPP');
    // const result = await upgrades.deployProxy(DAPP, { kind: 'uups' });
    // console.log("address>>>>DAPP>>>>>>", result.address)

    const DAPP = await ethers.getContractFactory("DAPP");
    const upgraded = await upgrades.upgradeProxy("0x33eBf00e7E2b6c5B5768fBa452D6967E339db307", DAPP);
    console.log(upgraded.address);

    
  });
});
