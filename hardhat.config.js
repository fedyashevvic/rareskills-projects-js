require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-erc1820");
// require('solidity-coverage');


module.exports = {
  networks: {
    hardhat: {},
    // goeril: {
    //   url: process.env.ALCHEMY_GOERLI,
    //   accounts: [
    //     process.env.TESTNET_GOERIL_KEY
    //   ],
    // },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.17",
      },
      {
        version: "0.8.15",
      },
      {
        version: "0.5.3",
      },
      {
        version: "0.7.0",
      },

    ],
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
