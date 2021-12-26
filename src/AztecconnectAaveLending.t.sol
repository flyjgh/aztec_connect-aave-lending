// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import { AaveLendingBridge } from "./AztecconnectAaveLending.sol";
import { Types } from "./interfaces/Types.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";
import { IProtocolDataProvider } from "./interfaces/IProtocolDataProvider.sol";
import { ILendingPoolAddressesProvider } from "./interfaces/ILendingPoolAddressesProvider.sol";

contract AztecconnectAaveLendingTest is DSTest {
    AaveLendingBridge lending;

    address AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address testaddress = 0x6619D9498BE3f928d64492aa4f896730419B9E94;

    AaveLendingBridge bridge;

    Types.AztecAsset aave;
    Types.AztecAsset weth;
    Types.AztecAsset inputAssetA;
    Types.AztecAsset outputAssetA;
    Types.AztecAsset inputAssetB  = Types.AztecAsset(0, address(0x1), Types.AztecAssetType.ERC20);
    Types.AztecAsset outputAssetB = Types.AztecAsset(1, address(0x1), Types.AztecAssetType.ERC20);

    uint256 inputValue;

    function setUp() public {
        bridge = new AaveLendingBridge(address(this));
        weth   = Types.AztecAsset(1, WETH, Types.AztecAssetType.ERC20);
        aave   = Types.AztecAsset(2, AAVE, Types.AztecAssetType.ERC20); 
        inputAssetA  = aave;
        outputAssetA = weth;
    }

    receive() external payable {}
    fallback() external payable {}
    
    function test_deposit() public {

        uint256 preBalanceIn  = address(bridge).balance;
        uint256 preBalanceOut = IERC20(outputAssetA.erc20Address).balanceOf(address(this));

        (bool sent, ) = address(bridge).call{value: 1 ether}("");

        emit log_named_uint("balance: ", address(bridge).balance);

        bridge.convert(
        inputAssetA,
        inputAssetB,
        outputAssetA,
        outputAssetB,
        inputValue,
        0,
        0
        );

        uint256 postBalanceIn  = address(bridge).balance;
        uint256 postBalanceOut = IERC20(outputAssetA.erc20Address).balanceOf(address(this));
        assertEq(preBalanceIn - inputValue, postBalanceIn);
    }

    function test_withdraw() public {

        test_deposit();
        
        uint256 preBalanceIn  = address(bridge).balance;
        uint256 preBalanceOut = IERC20(outputAssetA.erc20Address).balanceOf(address(this));

        bridge.convert(
        inputAssetA,
        inputAssetB,
        outputAssetA,
        outputAssetB,
        inputValue,
        0,
        1
        );

        uint256 postBalanceIn  = address(bridge).balance;
        uint256 postBalanceOut = IERC20(outputAssetA.erc20Address).balanceOf(address(this));
        assertEq(preBalanceIn - inputValue, postBalanceIn);
    }
}
