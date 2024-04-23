// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./CrocSwapDex.sol";  // CrocSwap Dex functionality
import "./CrocSwapRouter.sol";  // Router for interacting with CrocSwap Dex

/**
 * @title Tempest Vault
 * @dev Main vault contract, similar to AlphaProVault but integrated with CrocSwap functionalities
 */
contract TempestVault is ERC20Upgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    CrocSwapDex public crocSwapDex;
    CrocSwapRouter public crocSwapRouter;

    // Event definitions
    event TokensDeposited(address indexed user, uint256 amount0, uint256 amount1);
    event TokensSwapped(address indexed user, int128 amount0, int128 amount1);

    function initialize(
        string memory name_,
        string memory symbol_,
        address crocSwapDexAddress,
        address crocSwapRouterAddress
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ReentrancyGuard_init();
        crocSwapDex = CrocSwapDex(crocSwapDexAddress);
        crocSwapRouter = CrocSwapRouter(crocSwapRouterAddress);
    }

    /**
     * @notice Deposit tokens to be used for liquidity provision
     * @param token The token address
     * @param amount Amount of tokens to deposit
     */
    function deposit(address token, uint256 amount) public returns (uint256) {
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        emit TokensDeposited(msg.sender, amount, 0);
        return amount;
    }

    /**
     * @notice Swap tokens using the integrated CrocSwap functionality
     * @param base Base token address
     * @param quote Quote token address
     * @param amount Amount of base token to swap
     * @param isBuy Direction of swap, true if buying quote token
     * @return baseFlow The flow of the base token
     * @return quoteFlow The flow of the quote token
     */
    function swapTokens(address base, address quote, uint256 amount, bool isBuy) public returns (int128 baseFlow, int128 quoteFlow) {
        uint256 poolIdx = 0; // Default pool index, modify as necessary for your use case
        bool inBaseQty = true; // Assuming quantity is in terms of the base token
        uint128 qty = uint128(amount);
        uint16 tip = 0; // Default tip, adjust if your implementation requires
        uint128 limitPrice = 0; // No limit price set
        uint128 minOut = 0; // No minimum output set
        uint8 reserveFlags = 0; // Default reserve flags

        (baseFlow, quoteFlow) = crocSwapRouter.swap(base, quote, poolIdx, isBuy, inBaseQty, qty, tip, limitPrice, minOut, reserveFlags);
        emit TokensSwapped(msg.sender, baseFlow, quoteFlow);
        return (baseFlow, quoteFlow);
    }

    // Additional functions to handle liquidity management, rebalancing, etc., could be added here
}
