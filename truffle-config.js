const HDWalletProvider = require('@truffle/hdwallet-provider');
const dotenv = require('dotenv');

dotenv.config();

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
    },
    goerli: {
      provider: () => new HDWalletProvider(process.env.PRIVATE_KEY, `https://goerli.infura.io/v3/${process.env.INFURA_PROJECT_ID_GOERLI}`),
      network_id: 5,
      gas: 5500000,
      gasPrice: 20000000000, // 20 Gwei
    },
  },
  compilers: {
    solc: {
      version: '0.8.18',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },
};
