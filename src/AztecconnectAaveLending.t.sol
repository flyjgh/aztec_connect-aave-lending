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

    address WETH  = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address aWETH = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address AAVE  = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address aAAVE = 0xFFC97d72E13E01096502Cb8Eb52dEe56f74DAD7B;
    address testAddress = 0xddfAbCdc4D8FfC6d5beaf154f18B778f892A0740;

    AaveLendingBridge bridge;

    Types.AztecAsset eth;
    Types.AztecAsset weth;
    Types.AztecAsset aave;
    Types.AztecAsset aweth;
    Types.AztecAsset aaave;
    Types.AztecAsset inputAssetA;
    Types.AztecAsset outputAssetA;
    Types.AztecAsset inputAssetB  = Types.AztecAsset(0, address(0x1), Types.AztecAssetType.ERC20);
    Types.AztecAsset outputAssetB = Types.AztecAsset(1, address(0x1), Types.AztecAssetType.ERC20);

    uint256 inputValue;
    uint256 out;

    function setUp() public {
        bridge = new AaveLendingBridge(address(this));
        eth    = Types.AztecAsset(0, WETH, Types.AztecAssetType.ETH);
        weth   = Types.AztecAsset(1, WETH, Types.AztecAssetType.ERC20);
        aave   = Types.AztecAsset(2, AAVE, Types.AztecAssetType.ERC20); 
        aweth  = Types.AztecAsset(3, aWETH, Types.AztecAssetType.ERC20);
        aaave  = Types.AztecAsset(4, aAAVE, Types.AztecAssetType.ERC20); 
        inputValue = 1 ether;
    }

    receive() external payable {}
    fallback() external payable {}
    
    function test_deposit_ERC20() public {

        inputAssetA  = aave;
        outputAssetA = aaave;

        IERC20(AAVE).transfer(address(bridge), inputValue);

        uint256 preBalanceIn  = IERC20(inputAssetA.erc20Address).balanceOf(address(bridge));
        uint256 preBalanceOut = IERC20(outputAssetA.erc20Address).balanceOf(address(bridge));

        emit log_named_uint("balanceIn: ", preBalanceIn);
        emit log_named_uint("balanceOut: ", preBalanceOut);

        (out,,)=bridge.convert(
        inputAssetA,
        inputAssetB,
        outputAssetA,
        outputAssetB,
        inputValue,
        0,
        0
        );

        uint256 postBalanceIn  = IERC20(inputAssetA.erc20Address).balanceOf(address(bridge));
        uint256 postBalanceOut = IERC20(outputAssetA.erc20Address).balanceOf(address(bridge));
        assertEq(preBalanceIn - inputValue, postBalanceIn);
        assertEq(preBalanceOut + out, postBalanceOut);
    }

    function test_deposit_ETH() public {

        inputAssetA  = eth;
        outputAssetA = aweth;
        
        (bool sent, ) = address(bridge).call{value: 1 ether}("");

        uint256 preBalanceIn  = address(bridge).balance;
        uint256 preBalanceOut = IERC20(outputAssetA.erc20Address).balanceOf(address(bridge));

        emit log_named_uint("balanceIn: ", preBalanceIn);
        emit log_named_uint("balanceOut: ", preBalanceOut);

        (out,,)=bridge.convert(
        inputAssetA,
        inputAssetB,
        outputAssetA,
        outputAssetB,
        inputValue,
        0,
        0
        );

        uint256 postBalanceIn  = address(bridge).balance;
        uint256 postBalanceOut = IERC20(outputAssetA.erc20Address).balanceOf(address(bridge));
        assertEq(preBalanceIn - inputValue, postBalanceIn);
        assertEq(preBalanceOut + out, postBalanceOut);
    }

    function test_withdraw_ERC20() public {

        test_deposit_ERC20();

        inputAssetA  = aaave;
        outputAssetA = aave;
        
        bridge.convert(
        inputAssetA,
        inputAssetB,
        outputAssetA,
        outputAssetB,
        inputValue/2,
        0,
        1
        );

    }

    function test_withdraw_ETH() public {

        test_deposit_ETH();
        
        inputAssetA  = aweth;
        outputAssetA = eth;

        bridge.convert(
        inputAssetA,
        inputAssetB,
        outputAssetA,
        outputAssetB,
        inputValue/2,
        0,
        1
        );

    }
}
