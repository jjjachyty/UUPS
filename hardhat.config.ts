import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
      evmVersion: "istanbul"
    },
  },
  sourcify: {
    enabled: true
  },
  paths: {
    artifacts: './src/artifacts',
  },
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
      accounts: [" "]
    },
    mainnet: {
      url: "https://rpc.ankr.com/bsc",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [" "]
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
    apiKey: "CSHJ7566PNDEJJU2PJJK2RQSW7CPD4A9DT"
  },
};

export default config;
