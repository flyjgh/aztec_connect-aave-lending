// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6 ^0.8.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "./interfaces/SafeMath.sol";
// import { IERC20 } from "./interfaces/IERC20.sol";

import { IDefiBridge } from "./interfaces/IDefiBridge.sol";
import { Types } from "./interfaces/Types.sol";
import { ILendingPoolAddressesProvider } from "./interfaces/ILendingPoolAddressesProvider.sol";
import { IProtocolDataProvider } from "./interfaces/IProtocolDataProvider.sol";
import { IWETHGateway } from "./interfaces/IWETHGateway.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";
import { IERC20 } from "./interfaces/IERC20.sol";

contract AaveLendingBridge is IDefiBridge {
    using SafeMath for uint256;

    address public immutable rollupProcessor;
    address public weth;

    ILendingPoolAddressesProvider immutable provider;
    IProtocolDataProvider immutable protocolDataProvider;
    IWETHGateway immutable wethGateway;
    address lendingPoolAddress;
    ILendingPool lendingPool;

    constructor(address _rollupProcessor) {
        rollupProcessor = _rollupProcessor;
        provider = ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
        protocolDataProvider = IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
        wethGateway = IWETHGateway(0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04);
    }

    receive() external payable {}

    function convert(
        Types.AztecAsset calldata inputAssetA,
        Types.AztecAsset calldata,
        Types.AztecAsset calldata outputAssetA,
        Types.AztecAsset calldata,
        uint256 inputValue,
        uint256,
        uint64 mode
        )
        external
        payable
        override
        returns (
            uint256 outputValueA,
            uint256,
            bool isAsync
        )
        {
        require(msg.sender == rollupProcessor, "AaveLendingBridge: INVALID_CALLER");
        isAsync = false;

        lendingPoolAddress = provider.getLendingPool();
        lendingPool = ILendingPool(lendingPoolAddress);

        address ETH  = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address aWETH;


        // When depositing, the LendingPool contract must have allowance() to spend funds on behalf of msg.sender for the
        // amount to be deposited. This can be done via the standard ERC20 approve() method.
        
        // TODO This should check the asset can be lended on AAVE instead of blindly trying to lend.

        // 1 - deposit

        if (mode == 0) {

            if (inputAssetA.assetType == Types.AztecAssetType.ETH) {

                // Deposit `msg.value` amount of ETH
                // receive 1:1 of aWETH
                IERC20(WETH).approve(msg.sender, msg.value);
                IWETHGateway(wethGateway).depositETH(lendingPoolAddress, msg.sender, 0);

            }

            else if (inputAssetA.assetType == Types.AztecAssetType.ERC20) {

                // approve asset
                // call `deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)`
                IERC20(inputAssetA.erc20Address).approve(msg.sender, inputValue);
                lendingPool.deposit(inputAssetA.erc20Address, inputValue, msg.sender, 0);

            }

        }

        else if (mode == 1) {
            // 2 - withdraw

            if (inputAssetA.assetType == Types.AztecAssetType.ETH) {

                // withdraw `inputValue` amount of aWETH
                // receive 1:1 of ETH
                (aWETH,,) = protocolDataProvider.getReserveTokensAddresses(WETH);
                IERC20(aWETH).approve(lendingPoolAddress, inputValue);
                IWETHGateway(wethGateway).withdrawETH(lendingPoolAddress, inputValue, msg.sender);

            }

            else if (inputAssetA.assetType == Types.AztecAssetType.ERC20) {

                // approve asset
                // call `withdraw(address asset, uint256 amount, address to)`
                IERC20(inputAssetA.erc20Address).approve(lendingPoolAddress, inputValue);
                lendingPool.withdraw(inputAssetA.erc20Address, inputValue, msg.sender);

            }
        }
    }

  function canFinalise(
    uint256 /*interactionNonce*/
  ) external view override returns (bool) {
    return false;
  }

  function finalise(
    Types.AztecAsset calldata,
    Types.AztecAsset calldata,
    Types.AztecAsset calldata,
    Types.AztecAsset calldata,
    uint256,
    uint64
  ) external payable override returns (uint256, uint256) {
    require(false);
  }
}
