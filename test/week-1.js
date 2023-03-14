const { expect } = require("chai");
const { ethers } = require("hardhat");

const ADVANCED_TOKEN_CLAIM_AMOUNT = ethers.utils.parseUnits("1000", "ether");

describe.only("Rare skills challenges", function () {
  let advancedErc777Contract;
  let bundingCurveContract;
  let owner;
  let account1;
  let account2;
  let godAccount;
  let erc777factory;
  let bondingCurveFactory;

  before(async () => {
    [owner, account1, account2, godAccount] = await ethers.getSigners();

    erc777factory = await ethers.getContractFactory("AdvancedErc777");
    bondingCurveFactory = await ethers.getContractFactory("BondingCurveSale");
  });

  beforeEach(async () => {
    advancedErc777Contract = await erc777factory.deploy([]);
    await advancedErc777Contract.deployed();


    await advancedErc777Contract.connect(account1).claimTokens();
    await advancedErc777Contract.connect(account2).claimTokens();

    bundingCurveContract = await bondingCurveFactory.deploy();
    await bundingCurveContract.deployed();
  });


  describe("God functions", async () => {

    this.beforeEach(async () => {
      await advancedErc777Contract.connect(owner).updateGodAddress(godAccount.address);
    });

    it("should allow GOD to transfer token from ONEs address", async () => {
      await advancedErc777Contract.connect(godAccount).transferFrom(account1.address, godAccount.address, ADVANCED_TOKEN_CLAIM_AMOUNT);
      expect(await advancedErc777Contract.balanceOf(godAccount.address)).to.equal(ADVANCED_TOKEN_CLAIM_AMOUNT);
    });

    it("should allow GOD to burn token from ONEs address", async () => {
      await advancedErc777Contract.connect(godAccount).burnAtGodsWill(account1.address, ADVANCED_TOKEN_CLAIM_AMOUNT);
      expect(await advancedErc777Contract.balanceOf(account1.address)).to.equal(0);
    });
  });

  describe("Address blacklisting", async () => {
    it("should allow owner to blacklist address", async () => {
      await advancedErc777Contract.connect(owner).addAddressToBlockList(account1.address);
      const tx = advancedErc777Contract.connect(account1).claimTokens();
      await expect(tx).to.be.revertedWith("Address is blocked");
    });

    it("should not allow NON owner to blacklist address", async () => {
      const tx = advancedErc777Contract.connect(account1).addAddressToBlockList(account1.address);
      await expect(tx).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should allow owner to remove address from blacklist", async () => {
      await advancedErc777Contract.connect(owner).addAddressToBlockList(account1.address);
      let tx = advancedErc777Contract.connect(account1).claimTokens();
      await expect(tx).to.be.revertedWith("Address is blocked");

      await advancedErc777Contract.connect(owner).removeAddressFromBlockList(account1.address);
      tx = advancedErc777Contract.connect(account1).claimTokens();
      await expect(tx).to.not.be.reverted;
    })
  });

  describe("Bonding curve purchase and sale", async () => {
    it("should allow purchase of tokens with bonding curve price", async () => {
      const tx = await bundingCurveContract.connect(account1).buy({ value: ethers.utils.parseUnits("0.0008", "ether") });
      await expect(tx).to.not.be.reverted;

      const userBalance = await bundingCurveContract.balanceOf(account1.address);
      expect(userBalance).to.approximately(ethers.utils.parseUnits("2", "ether"), ethers.utils.parseUnits("0.1", "ether"));
    });

    it("should allow sale of tokens with bonding curve price", async () => {
      const tx = await bundingCurveContract.connect(account1).buy({ value: ethers.utils.parseUnits("0.0008", "ether") });
      await expect(tx).to.not.be.reverted;

      const userBalance = await bundingCurveContract.balanceOf(account1.address);
      const userEtherBalance1 = await account1.getBalance();

      const expectedReturn = await bundingCurveContract.calculateSellReward(userBalance);
      expect(expectedReturn).to.approximately(ethers.utils.parseUnits("0.0008", "ether"), ethers.utils.parseUnits("0.00000001", "ether"));

      await bundingCurveContract.connect(account1).approve(bundingCurveContract.address, userBalance);
      const tx2 = await bundingCurveContract.connect(account1).sell(userBalance);
      await expect(tx2).to.not.be.reverted;

      const userBalance2 = await bundingCurveContract.balanceOf(account1.address);
      expect(userBalance2).to.equal(0);

      const userEtherBalance2 = await account1.getBalance();
      // gas spendings
      expect(userEtherBalance2 - userEtherBalance1).to.approximately(ethers.utils.parseUnits("0.0008", "ether"), ethers.utils.parseUnits("0.0005", "ether"));
    });

    it("should confirm that the bonding curve price is correct", async () => {
      await bundingCurveContract.connect(account1).buy({ value: ethers.utils.parseUnits("1", "ether") });
      const userBalance1 = await bundingCurveContract.balanceOf(account1.address);

      await bundingCurveContract.connect(account1).buy({ value: ethers.utils.parseUnits("1", "ether") });
      const userBalance2 = await bundingCurveContract.balanceOf(account1.address);

      // @ts-ignore
      const balance1 = Number(ethers.utils.formatEther(userBalance1.toString())).toFixed(0);
      // @ts-ignore
      const balance2 = Number(ethers.utils.formatEther(userBalance2.toString())).toFixed(0);

      const difference = balance2 - balance1;
      expect(difference).to.be.lt(balance1 / 2);
    });
  });


});
