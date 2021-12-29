// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6 ^0.8.0;
pragma experimental ABIEncoderV2;

import { SafeMath }                      from "./library/SafeMath.sol";
import { Types }                         from "./library/Types.sol";

import { IERC20 }                        from "./interfaces/IERC20.sol";
import { IDefiBridge }                   from "./interfaces/IDefiBridge.sol";
import { IWETHGateway }                  from "./interfaces/IWETHGateway.sol";
import { ILendingPool }                  from "./interfaces/ILendingPool.sol";
import { IProtocolDataProvider }         from "./interfaces/IProtocolDataProvider.sol";
import { ILendingPoolAddressesProvider } from "./interfaces/ILendingPoolAddressesProvider.sol";

contract AaveLendingBridge is IDefiBridge {
    using SafeMath for uint256;

    address public immutable rollupProcessor;
    address immutable wethGatewayAddress;
    address immutable lendingPoolAddress;
    address aToken;

    IWETHGateway immutable wethGateway;
    ILendingPool immutable lendingPool;
    IProtocolDataProvider immutable DataProvider;

    constructor(address _rollupProcessor) {
      
        ILendingPoolAddressesProvider provider;

        rollupProcessor    = _rollupProcessor;
        provider           = ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
        DataProvider       = IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
        wethGatewayAddress = 0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04;
        wethGateway        = IWETHGateway(0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04);
        lendingPoolAddress = provider.getLendingPool();
        lendingPool        = ILendingPool(provider.getLendingPool());
    }

    receive() external payable {}

    function convert(
        Types.AztecAsset calldata inputAsset,
        Types.AztecAsset calldata,
        Types.AztecAsset calldata outputAsset,
        Types.AztecAsset calldata,
        uint256 inputValue,
        uint256,
        uint64
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

        // checks if the ROLLUP-PROCESSOR wants to make a deposit or borrow call.
        // if the outputAsset is VIRTUAL, the deposit function is called.
        if (outputAsset.assetType == Types.AztecAssetType.VIRTUAL) {                             // deposit

        // check that the asset can be lended on AAVE
        (aToken,,) = DataProvider.getReserveTokensAddresses(inputAsset.erc20Address);
        require(aToken != address(0x0), "AaveLendingBridge: INVALID_TOKEN");

            if (inputAsset.assetType == Types.AztecAssetType.ETH) {

                // Deposit `msg.value` amount of ETH
                // receive 1:1 of aWETH
                wethGateway.depositETH{ value: inputValue }(lendingPoolAddress, rollupProcessor, 0);

                // Return aWETH position
                outputValue = inputValue;

            }

            else if (inputAsset.assetType == Types.AztecAssetType.ERC20) {

                // set allowance of inputAsset
                // call `deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)`
                IERC20(inputAsset.erc20Address).approve(lendingPoolAddress, inputValue);
                lendingPool.deposit(inputAsset.erc20Address, inputValue, rollupProcessor, 0);

                // Return aToken position
                outputValue = inputValue;

            }
        }

        // if the inputAsset is VIRTUAL, the withdraw() function is called.
        else if (inputAsset.assetType == Types.AztecAssetType.VIRTUAL) {                         // withdraw

        // check that the asset can be withdrawn on AAVE
        (aToken,,) = DataProvider.getReserveTokensAddresses(outputAsset.erc20Address);
        require(aToken != address(0x0), "AaveLendingBridge: INVALID_TOKEN");

            if (outputAsset.assetType == Types.AztecAssetType.ETH) {

                // set allowance of aWETH
                // withdraw `inputValue` amount of ETH
                IERC20(inputAsset.erc20Address).approve(wethGatewayAddress, inputValue);
                wethGateway.withdrawETH(lendingPoolAddress, inputValue, rollupProcessor);

                // Return withdrawn ETH amount
                outputValue = inputValue;

            }

            else if (outputAsset.assetType == Types.AztecAssetType.ERC20) {

                // set allowance of inputAsset
                // call `withdraw(address asset, uint256 amount, address to)`
                IERC20(inputAsset.erc20Address).approve(lendingPoolAddress, inputValue);
                lendingPool.withdraw(outputAsset.erc20Address, inputValue, rollupProcessor);

                // Return withdrawn ERC20 amount
                outputValue = inputValue;

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
