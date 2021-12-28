// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6 ^0.8.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "./interfaces/SafeMath.sol";
import { IERC20 } from "./interfaces/IERC20.sol";

import { IDefiBridge } from "./interfaces/IDefiBridge.sol";
import { Types } from "./interfaces/Types.sol";
import { ILendingPoolAddressesProvider } from "./interfaces/ILendingPoolAddressesProvider.sol";
import { IProtocolDataProvider } from "./interfaces/IProtocolDataProvider.sol";
import { IWETHGateway } from "./interfaces/IWETHGateway.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";

contract AaveLendingBridge is IDefiBridge {
    using SafeMath for uint256;

    address public immutable rollupProcessor;
    address immutable wethGatewayAddress;
    address immutable WETH;
    address aToken;
    address lendingPoolAddress;

    ILendingPoolAddressesProvider immutable provider;
    IProtocolDataProvider immutable DataProvider;
    IWETHGateway immutable wethGateway;
    ILendingPool lendingPool;

    constructor(address _rollupProcessor) {
        rollupProcessor = _rollupProcessor;
        provider = ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
        DataProvider = IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
        wethGatewayAddress = 0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04;
        wethGateway = IWETHGateway(0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04);
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    receive() external payable {}

    function convert(
        Types.AztecAsset calldata asset,
        Types.AztecAsset calldata,
        Types.AztecAsset calldata,
        Types.AztecAsset calldata,
        uint256 inputValue,
        uint256,
        uint64 mode
        )
        external
        payable
        override
        returns (
            uint256 outputValue,
            uint256,
            bool isAsync
        )
        {
        require(msg.sender == rollupProcessor, "AaveLendingBridge: INVALID_CALLER");
        isAsync = false;

        lendingPoolAddress = provider.getLendingPool();
        lendingPool = ILendingPool(lendingPoolAddress);

        // TODO This should check the asset can be lended on AAVE instead of blindly trying to lend.

        // `mode` input selects the function to call.
        // 0: deposit `token`, receive corresponding aToken.
        // 1: withdraw `token`, redeem corresponding aToken.

        if (mode == 0) { // deposit

            if (asset.assetType == Types.AztecAssetType.ETH) {

                //check balance of output aToken
                (aToken,,) = DataProvider.getReserveTokensAddresses(asset.erc20Address);
                uint preBalance = IERC20(aToken).balanceOf(address(msg.sender));

                // Deposit `msg.value` amount of ETH
                // receive 1:1 of aWETH
                wethGateway.depositETH{ value: inputValue }(lendingPoolAddress, msg.sender, 0);
                
                outputValue = preBalance - IERC20(aToken).balanceOf(address(msg.sender));

            }

            else if (asset.assetType == Types.AztecAssetType.ERC20) {

                //check balance of output aToken
                (aToken,,) = DataProvider.getReserveTokensAddresses(asset.erc20Address);
                uint preBalance = IERC20(aToken).balanceOf(address(msg.sender));

                // approve asset
                // call `deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)`
                IERC20(asset.erc20Address).approve(lendingPoolAddress, inputValue);
                lendingPool.deposit(asset.erc20Address, inputValue, msg.sender, 0);

                outputValue = preBalance - IERC20(aToken).balanceOf(address(msg.sender));

            }
        }

        else if (mode == 1) { // withdraw

            if (asset.assetType == Types.AztecAssetType.ETH) {

                //check balance of ETH
                uint preBalance = address(msg.sender).balance;

                // withdraw `inputValue` amount of aWETH
                // receive 1:1 of ETH
                (aToken,,) = DataProvider.getReserveTokensAddresses(asset.erc20Address);
                IERC20(aToken).approve(wethGatewayAddress, inputValue);
                wethGateway.withdrawETH(lendingPoolAddress, inputValue, msg.sender);

                outputValue = preBalance - address(msg.sender).balance;

            }

            else if (asset.assetType == Types.AztecAssetType.ERC20) {

                //check balance of token to withdraw
                uint preBalance = IERC20(asset.erc20Address).balanceOf(address(msg.sender));

                // approve asset
                // call `withdraw(address asset, uint256 amount, address to)`
                (aToken,,) = DataProvider.getReserveTokensAddresses(asset.erc20Address);
                IERC20(asset.erc20Address).approve(lendingPoolAddress, inputValue);
                lendingPool.withdraw(asset.erc20Address, inputValue, msg.sender);
                
                outputValue = preBalance - IERC20(asset.erc20Address).balanceOf(address(msg.sender));

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
