require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: "0.8.18",
  networks: {
    hardhat: {
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s2.binance.org:8545",
      chainId: 97,
      gasPrice: 50000000000,
      accounts: ["6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f"]
    },
    mainnet: {
      url: "https://rpc.ankr.com/bsc",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: ["6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f"]
    }
  },
};
