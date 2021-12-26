# Aztec-connect to Aave lending bridge

## Description

this repo contains a bridge contract (`AaveLendingBridge`) that connects the [Aztec-connect](https://medium.com/aztec-protocol/private-defi-with-the-aztec-connect-bridge-76c3da76d982) protocol to the Aave `deposit()` and `withdraw()` functions.

## Usage

to perform a deposit or a withdraw, call the `convert()` function with the following parameters:

* `inputAssetA`: the asset to deposit or withdraw
* `outputAssetA`: the aToken you receive in exchange of a deposit, or the token you withdraw
* `inputValue`: the amount of inputAssetA to deposit or withdraw
* `mode`: 0 for deposit, 1 for withdraw
