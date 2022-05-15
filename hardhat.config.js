//  hardhat.config.js

require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');



// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.3",
    settings: {
      optimizer: {
        enabled: true
      }
     }
    },
  networks: {
    hardhat: {
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: ["6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f"]
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: ["83b1a7a82b20860c4f14328e11ed46ee827da1c5698768ae74900cb2c5baf6aa"]
    }
  },
};