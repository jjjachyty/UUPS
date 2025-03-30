import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.25",
    settings: {
      optimizer: {
        enabled: true,
        // 降低runs值以优化部署大小
        runs: 200,
        // 添加详细优化设置
        details: {
          yul: true,
          yulDetails: {
            stackAllocation: true,
            optimizerSteps: "dhfoDgvulfnTUtnIf"
          },
        },
      },
      // 更新到更现代的EVM版本
      evmVersion: "shanghai",
      // 对大型合约禁用viaIR可能会有帮助
      viaIR: true
    },
  },
  paths: {
    // artifacts: './src/artifacts',
    sources:'./contracts'
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
      accounts: ["6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f"]
    },
    mainnet: {
      url: "https://bsc.nodereal.io",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: ["6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f"]
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
    apiKey: "CSHJ7566PNDEJJU2PJJK2RQSW7CPD4A9DT"
  },
};

export default config;
