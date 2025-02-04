# Sui Move Asset Bank

This repository contains a Sui Move module that implements a generic multi-asset bank. Users can deposit coins 
of any type and receive a non-transferrable NFT receipt. They can later redeem that receipt to withdraw their 
deposited funds.

## Features

- **Generic Deposits**: Deposit `Coin<T>` where T can be any coin (e.g., SUI, USDC, USDT)
- **NFT Receipt**: NFT token to represent the deposit
- **Withdrawal**: Redeem NFT to withdraw the exact amount deposited
- **Counters**: Tracks total deposits and active NFT receipts

## Overview

### `AssetBank`
A shared Sui object published once via the `init` (or `create_asset_bank` for test purposes) function that keeps:
1. An unique ID of the bank
2. A deposit counter
3. A count of currently active (unredeemed) NFTs

### `Receipt<T>`
An NFT object representing a deposit receipt:
- Non-transferable, only the depositor can redeem it for withdrawal
- Tracks:
  - `deposit_number`
  - `depositor` address
  - `amount`

### Key Entry Functions

1. **`init_bank(ctx: &mut TxContext)`**
   - Publishes a new `AssetBank` object as a shared object

2. **`deposit<T>(bank: &mut AssetBank, coin: Coin<T>, ctx: &mut TxContext)`**
   - Deposits a `Coin<T>` into the bank
   - Mints a `Receipt<T>` NFT and sends to the depositor

3. **`withdraw<T>(bank: &mut AssetBank, receipt: Receipt<T>, ctx: &mut TxContext)`**
   - Burns the NFT (i.e. `Receipt<T>`) and returns the original deposit

### Usage

1. **Publish Module**
   ```bash
   sui move build
   sui move test
   sui client publish --gas-budget <GAS_BUDGET>
