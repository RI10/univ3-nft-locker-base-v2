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

---

## Troubleshooting

**1. Gas estimation failed**
- Happens in Remix when trying to withdraw before `unlockTime`, or from a non-owner address.  
- Also occurs if `tokenId` was never transferred to the locker (the contract holds nothing).  
🧩 *Fix:* confirm you are the deployer, `unlockTime` has passed, and the NFT is inside the locker (`ownerOf(tokenId)` → locker address).

**2. Verification error: “Unable to generate contract Bytecode and ABI”**
- BaseScan sometimes fails if Remix uses “evmVersion: cancun” or optimization = 200 runs.  
🧩 *Fix:* re-verify with compiler = `v0.8.26+commit.8a97fa7a`, optimization = 200, EVM = “default”, and paste parameters in single line.

**3. Multi-line input not supported**
- Happens if ABI-encoded constructor parameters are pasted with line breaks.  
🧩 *Fix:* remove all newlines → paste as a single continuous string.

**4. NFT not withdrawable**
- Locker does not support emergency unlocks. If NFT was sent to wrong address or locked forever — it cannot be recovered.  
🧩 *Fix:* always test on small LPs first, verify all constructor parameters before final deployment.


---

## Recommendations (lessons learned)

- **Verify before locking**: always verify the locker contract on BaseScan/Etherscan *before* transferring the LP NFT.
- **Start tiny**: test with a small fresh LP and a very short lock (5–10 minutes). Only then repeat with real liquidity and a longer lock.
- **Double-check constructor args**: `nftManager`, `tokenId`, `unlockTime`. A single wrong value = unusable locker.
- **Prove ownership**: confirm `owner()` equals your deployer wallet and NPM `ownerOf(tokenId)` equals the locker address after transfer.
- **Keep compiler settings fixed**: use `solc 0.8.26`, optimizer **ON**, runs **200**, EVM **default** — the same in Remix and in verification.
- **Document the run**: store the locker address, tx hash of the NFT transfer, and a screenshot of `owner()/tokenId()/unlockTime()` for auditability.

---

## Verification notes (BaseScan & Remix settings)

- **Compiler version:** `v0.8.26+commit.8a97fa7a`
- **EVM version:** `default`
- **Optimizer:** enabled, `runs = 200`
- **Contract name:** `UniV3NFTLockerV2`
- **License:** MIT

**Constructor arguments (single line, comma-separated):**

---

## Testing checklist (safe deployment)

- [ ] **Compile** with `solc 0.8.26`, optimizer ON (runs 200), EVM default.
- [ ] **Verify** the contract on BaseScan *before* interacting with funds.
- [ ] **Dry run** with a tiny LP and **short lock** (5–10 minutes).
- [ ] **Record** the deployed locker address and tx hash.
- [ ] **Transfer NFT** to the locker; confirm on NPM `ownerOf(tokenId)` = locker address.
- [ ] **Read fields** on the locker: `owner()`, `tokenId()`, `unlockTime()`, `withdrawn() == false`.
- [ ] **Wait until unlockTime**, then call `withdrawNFT(your_address)` from the locker owner.
- [ ] **Confirm** NFT is back on your wallet (`ownerOf(tokenId)` = your address).
- [ ] Only after all checks **repeat** with real liquidity and a longer lock.

---

## Dry-run with a sacrificial LP-NFT (safe rehearsal)

**Why:** The locker interacts specifically with Uniswap V3’s `NonfungiblePositionManager` (NPM).  
Random ERC-721 “junk NFTs” will not work. Use a *tiny* Uniswap V3 LP position NFT as a sacrificial token.

### Steps

1. **Mint a micro position**  
   - Network: **Base mainnet**  
   - Pool: your target pair (e.g., mCRRX/WETH)  
   - Fee tier: same as the real pool  
   - Range: use a **wide range** (or full range) so the position is valid  
   - Liquidity: **minimal amounts** (so losing it won’t hurt)  
   - Result: you receive a **LP-NFT tokenId** from NPM

2. **Deploy & verify the locker**  
   - Compiler: `0.8.26`, optimizer **ON**, runs **200**, EVM **default**, license **MIT**  
   - Constructor (short lock):  
     ```
     <NPM_address>, <tokenId>, 600
     ```
     where `600` = 10 minutes

3. **Transfer the micro LP-NFT to the locker**  
   - In Uniswap UI or via explorer call `safeTransferFrom` (NPM) to the locker address  
   - Confirm on NPM: `ownerOf(tokenId)` must equal the **locker address**

4. **Wait until unlock**  
   - Ensure `unlockTime <= now` (read from the locker)

5. **Withdraw rehearsal**  
   - Call `withdrawNFT(<your_wallet_address>)` from the locker **owner**  
   - Confirm NPM `ownerOf(tokenId)` now equals **your wallet**;  
     the NFT should reappear in Uniswap → Pools

### Notes & Safety

- This is a **rehearsal** path: if something goes wrong, you only lose a *micro* LP, not real liquidity.  
- Do **not** use unrelated ERC-721s; only Uniswap V3 LP NFTs from the **same NPM** address work.  
- Keep screenshots / tx hashes of: deploy, transfer to locker, `ownerOf(tokenId)` before/after, withdraw call.  

