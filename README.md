# Aztec-connect to Aave lending bridge

## Description

this repo contains a bridge contract (`AaveLendingBridge`) that connects the [Aztec-connect](https://medium.com/aztec-protocol/private-defi-with-the-aztec-connect-bridge-76c3da76d982) protocol to the Aave `deposit()` and `withdraw()` functions.

## Usage

```solidity
function convert(
    Types.AztecAsset calldata inputAssetA,
    Types.AztecAsset calldata inputAssetB,
    Types.AztecAsset calldata outputAssetA,
    Types.AztecAsset calldata outputAssetB,
    uint256 inputValue,
    uint256 interactionNonce,
    uint64 auxData
)
external payable returns (uint256 outputValueA, uint256 outputValueB, bool isAsync);
```

to perform a deposit or a withdraw, call the `convert()` function with the following parameters:

* `inputAssetA` : the asset to deposit or withdraw
* `outputAssetA`: the aToken you receive in exchange of a deposit, or the token you withdraw
* `inputValue`  : the amount of inputAssetA to deposit or withdraw
* `mode`        : 0 for deposit, 1 for withdraw
