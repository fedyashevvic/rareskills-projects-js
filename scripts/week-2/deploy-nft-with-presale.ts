const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();
  // We get the contract to deploy
  console.log(`Deploying from ${owner.address}`);
  const factory = await hre.ethers.getContractFactory("NftWithPresale");
  const contract = await factory
    .connect(owner)
    .deploy(
      "ipfs://QmVRsXpYYp3qALoxjYUfNZAA6A28P86REKkoqadoXM5tLn/",
      "0x82063075e629a708D1c33a6637910666855eDd32",
      "0x00314e565e0574cb412563df634608d76f5c59d9f817e85966100ec1d48005c0"
    );

  await contract.deployed();
  console.log(`NftWithPresale contract deployed to: ${contract.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
