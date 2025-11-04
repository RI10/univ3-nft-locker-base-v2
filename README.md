# UniV3 NFT Locker – Base v2.0

A minimal on-chain **Uniswap V3 LP NFT locker** for **Base mainnet**.  
Holds one LP NFT until a fixed timestamp while still allowing fee collection.

---

### Why this exists
Centralized lock platforms (TeamFinance, PinkSale) either:
- charge ≈ $150 for each lock, or  
- still do not support **Uniswap V3 NFTs on Base**.  

This contract is a fully on-chain alternative — simple, transparent, free.

---

### Features
- Single LP NFT lock with fixed `UNLOCK_TIME`
- Fees remain claimable (`collectFees()`)
- Non-custodial: no admin keys
- Gas-cheap deployment on Base

---

### Network
| Item | Value |
|------|-------|
| Chain | **Base mainnet** |
| NonfungiblePositionManager | `0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1` |
| Example UNLOCK_TIME | `1762084088 (2025-11-02 11:48:08 UTC)` |

---

### How to use
1. **Deploy** the contract on Base (via Remix, Solidity 0.8.20+).  
2. **Transfer** your LP NFT (Uniswap V3 position) to the contract address.  
   - In Uniswap UI → *Pools → Manage → Transfer* → recipient = locker address  
   - or via BaseScan `safeTransferFrom(from, to, tokenId)`  
3. Verify that the locker now shows `UNI-V3-POS` under *Assets*.  
4. During the lock, call `collectFees()` any time.  
5. After `UNLOCK_TIME`, call `unlock()` to retrieve the NFT.

---

### Example workflow
```text
From: 0x9872…f31c
To:   0x096Ca4F83aB789e1020171F88420f36DA31d62CD
tokenId: 4121280

Once transferred, swaps in the mCRRX/WETH pool continue normally.

Deployment cost

≈ $0.1–0.2 in gas (on Base). No subscriptions, no fees.

Disclaimer

This code is provided "as is" without any warranty.
Use at your own risk and verify all addresses before sending assets.


---

## Known issues

- **Contract verification** — Some deployments failed to verify on BaseScan due to mismatched compiler or JSON settings. Unverified contracts hide source and ABI, making interaction harder.
- **Gas estimation failed** — When calling `withdrawNFT` in Remix, the transaction may revert with “Gas estimation failed”. Causes include:
  - Caller is not the locker `owner`
  - `unlockTime` not yet reached
  - The NFT is no longer owned by the locker (already transferred or burned)
- **Wrong constructor parameters** — If the locker was deployed with an incorrect `nftManager`, `tokenId`, or `unlockTime`, the NFT becomes unreachable.
- **Unverified NonfungiblePositionManager** — When the NPM contract on Base is unverified, debugging ownership issues for tokenId is more difficult.
- **No emergency unlock** — The minimal contract has no admin or emergency withdraw function. Once locked, NFT stays locked until `unlockTime`.

