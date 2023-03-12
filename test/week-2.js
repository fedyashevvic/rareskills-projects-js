import { expect } from "chai";
import { ethers, network } from "hardhat";
const { MerkleTree } = require('merkletreejs')
const keccak256 = require("keccak256");

const DAILY_YIELD_FROM_ONE_TOKEN = ethers.utils.parseUnits("10", "ether");
const DAILY_YIELD_FROM_FIVE_TOKENS = ethers.utils.parseUnits("50", "ether");

describe.only("Rare skills challenges", function () {
  let nft;
  let nftFactory;
  let token;
  let tokenFactory;
  let staking;
  let stakingFactory;
  let owner;
  let account1;
  let account2;
  let NFTWithPresaleContract;
  let NFTWithPresaleFactory;
  let NFTEnumerableContract;
  let NFTEnumerableFactory;
  let gameContract;
  let gameFactory;
  let contractToHack;
  let hacker;

  let contractToHack2;
  let hacker2;

  let root;
  let tree;
  let WHITELISTED_ADDRESSES;

  const getProof = (address) => {
    const tiketNum = WHITELISTED_ADDRESSES.indexOf(address);
    if (tiketNum === -1) throw new Error('Address not whitelisted');
    const leaf = keccak256(address, tiketNum);
    const proof = tree.getHexProof(leaf);
    console.log(`proof`, proof, leaf.toString('hex'), root)

    let v = tree.verify(proof, leaf, root)
    console.log(`valid`, v)

    return {
      proof,
      tiketNum
    }
  }

  before(async () => {
    [owner, account1, account2] = await ethers.getSigners();

    WHITELISTED_ADDRESSES = [account2.address, account1.address, owner.address, "0x154B4045F07B48C3B75D73a3f6C7C11Dfec95b4a", "0xA6856A6a15e6fDf2BE1857696fc4b1d7a75eACD6", "0x656b9e12Dd18F29eda9Cd87b56875cC599B55374", "0x82063075e629a708D1c33a6637910666855eDd32"];

    const leaves = WHITELISTED_ADDRESSES.map((x, i) => keccak256(x, i));
    tree = new MerkleTree(leaves, keccak256)
    root = tree.getRoot().toString('hex')

    nftFactory = await ethers.getContractFactory("NFT");
    tokenFactory = await ethers.getContractFactory("Token");
    stakingFactory = await ethers.getContractFactory("Staking");
    NFTEnumerableFactory = await ethers.getContractFactory("NFTEnumerable");
    gameFactory = await ethers.getContractFactory("GameContract");
    NFTWithPresaleFactory = await ethers.getContractFactory("NftWithPresale");

    let contractToHackFactory = await ethers.getContractFactory("Overmint1");
    contractToHack = await contractToHackFactory.deploy();

    let hackerContract = await ethers.getContractFactory("Overmint1Hack");
    hacker = await hackerContract.deploy(contractToHack.address);

    let contractToHack2Factory = await ethers.getContractFactory("Overmint2");
    contractToHack2 = await contractToHack2Factory.deploy();

    let hacker2Contract = await ethers.getContractFactory("Overmint2Hack");
    hacker2 = await hacker2Contract.deploy(contractToHack2.address, owner.address);
  });

  beforeEach(async () => {
    nft = await nftFactory.deploy();
    await nft.deployed();

    token = await tokenFactory.deploy();
    await token.deployed();

    staking = await stakingFactory.deploy(nft.address, token.address);
    await staking.deployed();

    await token.connect(owner).setStakingAddress(staking.address);

    NFTEnumerableContract = await NFTEnumerableFactory.deploy();
    await NFTEnumerableContract.deployed();

    gameContract = await gameFactory.deploy(NFTEnumerableContract.address);
    await gameContract.deployed();

    NFTWithPresaleContract = await NFTWithPresaleFactory.deploy("/", owner.address, `0x${root}`);
    await NFTWithPresaleContract.deployed();
  });

  describe("NFT contract with presale", async () => {
    it("Should allow user to mint NFT when sending sufficient funds", async () => {
      let tx = NFTWithPresaleContract.connect(account1).mint({ value: ethers.utils.parseUnits("0.01", "ether") });
      await expect(tx).to.be.not.reverted;

      expect(await NFTWithPresaleContract.balanceOf(account1.address)).to.equal(1);
    });

    it("Should not allow user to mint NFT when sending insufficient funds", async () => {
      let tx = NFTWithPresaleContract.connect(account1).mint({ value: ethers.utils.parseUnits("0.001", "ether") });
      await expect(tx).to.be.revertedWith("Ether value sent is not correct");
    });

    // it("Should allow user to mint nft on presale once", async () => {
    //   const { proof, tiketNum } = getProof(account1.address);
    //   let tx = await NFTWithPresaleContract.connect(account1).presale(tiketNum, proof, { value: ethers.utils.parseUnits("0.005", "ether") });
    //   await expect(tx).to.be.not.reverted;
    // });
  });


  describe("Staking functions", async () => {
    beforeEach(async () => {
      await nft.connect(account1).claim();
    });

    it("should allow user to stake NFT and return owner", async () => {
      await nft.connect(account1).setApprovalForAll(staking.address, true);
      await staking.connect(account1).deposit([1, 2, 3, 4, 5]);
      expect(await nft.ownerOf(1)).to.equal(staking.address);
      expect(await nft.balanceOf(staking.address)).to.equal(5);

      const ownerOfToken = await staking.ownerOf(1);
      expect(ownerOfToken).to.equal(account1.address);
    });

    it("should allow user to withdraw NFT", async () => {
      await nft.connect(account1).setApprovalForAll(staking.address, true);
      await staking.connect(account1).deposit([1, 2, 3, 4, 5]);
      await staking.connect(account1).withdraw([1, 2, 3]);
      expect(await nft.ownerOf(1)).to.equal(account1.address);
    });

    it("should not allow user to withdraw nft of other person", async () => {
      await nft.connect(account1).setApprovalForAll(staking.address, true);
      await staking.connect(account1).deposit([1, 2, 3, 4, 5]);
      let tx = staking.connect(account2).withdraw([1, 2, 3]);
      await expect(tx).to.be.revertedWith("Not the owner OR Token not staked");
    })
  });

  describe("ERC-20 token", async () => {
    it("Should not allow user to claim tokens directly on the contract", async () => {
      let tx = token.connect(account1).mint(account1.address, DAILY_YIELD_FROM_ONE_TOKEN);
      await expect(tx).to.be.revertedWith("Only staking contract can call this function");
    })

    it("Should allow owner to set staking address", async () => {
      let tx = token.connect(owner).setStakingAddress(staking.address);
      expect(tx).to.be.not.reverted;
    });

    it("Should not allow non-owner to set staking address", async () => {
      let tx = token.connect(account1).setStakingAddress(staking.address);
      await expect(tx).to.be.revertedWith("Ownable: caller is not the owner");
    });
  })

  describe("Token accumulation and claim functions", async () => {
    beforeEach(async () => {
      await nft.connect(account1).claim();
      await nft.connect(account1).setApprovalForAll(staking.address, true);
      await staking.connect(account1).deposit([1]);
      await network.provider.send("evm_increaseTime", [86400]);
      await network.provider.send("evm_mine");
    });

    it("Should accumulate reward for a user", async () => {
      const accumuated = await staking.connect(account1).getAccumulatedAmount(account1.address);
      expect(accumuated).to.equal(DAILY_YIELD_FROM_ONE_TOKEN);
    });

    it("Should allow user to claim reward", async () => {
      await staking.connect(account1).claim();
      expect(await token.balanceOf(account1.address)).to.approximately(DAILY_YIELD_FROM_ONE_TOKEN, ethers.utils.parseUnits("0.00015", "ether"));
    });

    it("Should accumulate reward from 0 after user claimed reward", async () => {
      await staking.connect(account1).claim();
      const accumuated = await staking.connect(account1).getAccumulatedAmount(account1.address);
      expect(accumuated).to.equal(0);
    });

    it("Should accumulate 5x reward from 5 tokens", async () => {
      await staking.connect(account1).claim();
      await staking.connect(account1).deposit([2, 3, 4, 5]);
      await network.provider.send("evm_increaseTime", [86400]);
      await network.provider.send("evm_mine");
      const accumuated = await staking.connect(account1).getAccumulatedAmount(account1.address);
      expect(accumuated).to.equal(DAILY_YIELD_FROM_FIVE_TOKENS);
    });
  });

  describe("ERC721 enumerable", async () => {
    it("Should return prime numbers if a holder NFT ids", async () => {
      const primeNumbers = await gameContract.getUserPrimeNfts(owner.address);
      expect(primeNumbers).to.deep.equal([2, 3, 5, 7, 11, 13, 17, 19]);
    });

    it("Should return empty array if user has no tokens", async () => {
      const primeNumbers = await gameContract.getUserPrimeNfts(account2.address);
      expect(primeNumbers).to.deep.equal([]);
    });
  });

  describe("Overmint Hack 1", async () => {
    it("Should hack overmint contract", async () => {
      const hackTx = hacker.hackMint();
      await expect(hackTx).to.be.not.reverted;
    });
  });

  describe("Overmint Hack 2", async () => {
    it("Should hack overmint contract", async () => {
      await contractToHack2.connect(owner).setApprovalForAll(hacker2.address, true);
      const hackTx = hacker2.hackMint();
      await expect(hackTx).to.be.not.reverted;
    });
  });
});
