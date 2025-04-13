import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';
import { ethers } from "ethers";
const BSC_URL = "https://data-seed-prebsc-1-s2.binance.org:8545";
 
 

var config: HardhatUserConfig = {
  solidity: {
    version: "0.8.25",
    settings: {
      optimizer: {
        enabled: true,
        // 降低runs值以优化部署大小
        runs: 1000,
     
      },
      // 更新到更现代的EVM版本
      evmVersion: "paris",
      // 对大型合约禁用viaIR可能会有帮助
      viaIR: true
    }},
  paths: {
    // artifacts: './src/artifacts',
    sources:'./contracts'
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      chainId:97,
      // hardfork: "shanghai", // 添加 hardfork 参数
      // forking: {
      //   url: BSC_URL,
      //   // 移除区块号参数，使用最新区块
      //   // blockNumber: 48119779,
      // }
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s2.binance.org:8545",
      chainId: 97,
      // gasPrice: 50000000000,
      accounts: [""]
    },
    mainnet: {
      url: "https://bsc.nodereal.io",
      chainId: 56,
      // gasPrice: 20000000000,
      accounts: [""]
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
    apiKey: "CSHJ7566PNDEJJU2PJJK2RQSW7CPD4A9DT"
  },
};

export default config;
