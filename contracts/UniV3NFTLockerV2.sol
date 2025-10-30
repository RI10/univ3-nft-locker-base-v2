// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * UniV3 NFT Locker (Base) – v2.0
 *
 * A minimal, non-custodial on-chain locker for a single Uniswap V3 LP NFT
 * on Base mainnet. The locker:
 *  - Accepts exactly one Uniswap V3 Position NFT (first one it receives).
 *  - Stores it until a fixed `UNLOCK_TIME` (hardcoded).
 *  - Allows claiming swap fees via `collectFees()` during the lock.
 *  - Does NOT allow decreasing liquidity, updating range, or transferring
 *    the NFT before `unlock()`.
 *  - Returns the NFT to the beneficiary (initial sender) after `UNLOCK_TIME`.
 *
 * No owner/admin keys. No external dependencies beyond the Uniswap V3 NPM.
 * Intended for transparency and low-cost locking on Base without relying on
 * centralized lockers.
 */

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// Minimal Uniswap V3 Position Manager interface for fee collection
interface INonfungiblePositionManager {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

contract UniV3NFTLockerV2 implements IERC721Receiver {
    /// @notice Base mainnet Uniswap V3 NonfungiblePositionManager (verified)
    /// https://basescan.org/address/0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1
    address public constant NPM = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;

    /// @notice Fixed unlock timestamp (Unix). Example: 2025-11-02 11:48:08 UTC
    /// If you need a different deadline, change this constant and redeploy.
    uint256 public constant UNLOCK_TIME = 1762084088;

    // --- State ---
    bool    public locked;        // the NFT has been received and locked
    bool    public withdrawn;     // the NFT has been returned
    uint256 public tokenId;       // locked Uniswap V3 position tokenId
    address public depositor;     // original sender of the NFT
    address public beneficiary;   // recipient of fees and NFT upon unlock

    // --- Events ---
    event Locked(address indexed from, uint256 indexed tokenId, uint256 until);
    event FeesCollected(address indexed to, uint256 amount0, uint256 amount1);
    event Unlocked(address indexed to, uint256 indexed tokenId);
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);

    /**
     * @dev Accept exactly one NFT from the NPM (first come, first served).
     *      Reverts if:
     *        - msg.sender is not NPM,
     *        - locker already holds/has withdrawn an NFT,
     *        - current time is past UNLOCK_TIME.
     *      Sets beneficiary = depositor (the sender of the NFT).
     */
    function onERC721Received(
        address /* operator */,
        address from,
        uint256 _tokenId,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        require(msg.sender == NPM, "UniV3NFTLockerV2: only NPM");
        require(!locked && !withdrawn, "UniV3NFTLockerV2: already set");
        require(block.timestamp < UNLOCK_TIME, "UniV3NFTLockerV2: lock expired");

        locked      = true;
        tokenId     = _tokenId;
        depositor   = from;
        beneficiary = from;

        emit Locked(from, _tokenId, UNLOCK_TIME);
        return this.onERC721Received.selector;
    }

    /**
     * @notice Change the beneficiary (optional). Can only be called by current beneficiary.
     */
    function setBeneficiary(address newBeneficiary) external {
        require(locked && !withdrawn, "UniV3NFTLockerV2: not active");
        require(msg.sender == beneficiary, "UniV3NFTLockerV2: only beneficiary");
        require(newBeneficiary != address(0), "UniV3NFTLockerV2: zero address");
        address old = beneficiary;
        beneficiary = newBeneficiary;
        emit BeneficiaryChanged(old, newBeneficiary);
    }

    /**
     * @notice Collect all accrued fees for the locked position to the beneficiary.
     * Anyone can call this; funds always go to `beneficiary`.
     */
    function collectFees() external returns (uint256 amount0, uint256 amount1) {
        require(locked && !withdrawn, "UniV3NFTLockerV2: not active");

        INonfungiblePositionManager.CollectParams memory p = INonfungiblePositionManager.CollectParams({
            tokenId:    tokenId,
            recipient:  beneficiary,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (amount0, amount1) = INonfungiblePositionManager(NPM).collect(p);
        emit FeesCollected(beneficiary, amount0, amount1);
    }

    /**
     * @notice Unlock and return the NFT to the beneficiary after UNLOCK_TIME has passed.
     */
    function unlock() external {
        require(locked && !withdrawn, "UniV3NFTLockerV2: not active");
        require(block.timestamp >= UNLOCK_TIME, "UniV3NFTLockerV2: too early");
        withdrawn = true;
        IERC721(NPM).safeTransferFrom(address(this), beneficiary, tokenId);
        emit Unlocked(beneficiary, tokenId);
    }
}
