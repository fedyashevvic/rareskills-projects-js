1. Contract NftWithPresale (contracts/module2/NftWithPresale.sol#9-130) has payable functions:
         - NftWithPresale.mint() (contracts/module2/NftWithPresale.sol#56-66)
         - NftWithPresale.presale(uint16,bytes32[]) (contracts/module2/NftWithPresale.sol#68-83)
        But does not have a function to withdraw the ether

2. NFT.claim() (contracts/module2/staking/nft.sol#12-17) has costly operations inside a loop:
        - _totalSupply ++ (contracts/module2/staking/nft.sol#15)

3. 0: NftWithPresale.constructor(string,address,bytes32)._royaltyAddress (contracts/module2/NftWithPresale.sol#32) lacks a zero-check on :
                - royaltyAddress = _royaltyAddress (contracts/module2/NftWithPresale.sol#36)

4. 0: Staking (contracts/module2/staking/staking.sol#12-115) should inherit from IERC721Receiver (node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol#11-27)

5. 0: GameContract.nftContract (contracts/module2/enumerable/gameContract.sol#7) should be immutable 

6. 0: Staking._claim(address) (contracts/module2/staking/staking.sol#85-92) performs a multiplication on the result of a division:
        - accumulatedAmount = (((block.timestamp - user.lastCheckpoint) * baseYield) / SECONDS_IN_DAY) * user.tokensStaked (contracts/module2/staking/staking.sol#87-88)

7. Different versions of Solidity are used: