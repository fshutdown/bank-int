module 0x1::bank {

    use sui::coin;
    use sui::object::{UID};
    use sui::tx_context::{TxContext, sender};
    use sui::transfer;
    use sui::{event};

    ////////////////////////////////////////////////////////////////////////////////
    // Error Codes
    ////////////////////////////////////////////////////////////////////////////////
    const E_ZERO_DEPOSIT: u64 = 1;
    const E_NOT_DEPOSITOR: u64 = 2;

    ////////////////////////////////////////////////////////////////////////////////
    // Resource Declarations
    ////////////////////////////////////////////////////////////////////////////////
    // The AssetBank is a Sui object (has a UID) that tracks the total number of
    // deposits ever made and the current number of active (unwithdrawn) deposit receipts.
    public struct AssetBank has key, store {
        id: UID,
        deposit_count: u64,
        active_nft_count: u64,
    }

    // The Receipt NFT is issued when a user deposits coins.
    // It holds the deposited coin along with metadata about the deposit.
    // (A warning is emitted because the generic type parameter 'T' is only used in a phantom context.
    // This warning is suppressed with an attribute.)
    #[allow(missing_phantom)]
    public struct Receipt<T> has key, store {
        id: UID,
        deposit_id: u64,
        depositor: address,
        amount: u64,
        coin: coin::Coin<T>,
    }

    // DepositEvent is emitted on deposit.
    public struct DepositEvent has copy, drop, store {
        deposit_id: u64,
        depositor: address,
        amount: u64,
    }

    // WithdrawEvent is emitted on withdrawal.
    public struct WithdrawEvent has copy, drop, store {
        deposit_id: u64,
        depositor: address,
        amount: u64,
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Initialization Function
    ////////////////////////////////////////////////////////////////////////////////
    /// This script function initializes the bank by creating an AssetBank object
    /// and publishing it into the caller’s account.
    public fun init_bank(ctx: &mut TxContext) {
        let bank = create_asset_bank(ctx);
        transfer::public_transfer<AssetBank>(bank, sender(ctx));
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Utility Function
    ////////////////////////////////////////////////////////////////////////////////
    public fun create_asset_bank(ctx: &mut TxContext): AssetBank {
        AssetBank {
            id: object::new(ctx),
            deposit_count: 0,
            active_nft_count: 0,
        }
    }

    public fun deposit_count(bank: &mut AssetBank): u64 { bank.deposit_count }
    public fun active_nft_count(bank: &mut AssetBank): u64 { bank.active_nft_count }

    ////////////////////////////////////////////////////////////////////////////////
    // Deposit Function
    ////////////////////////////////////////////////////////////////////////////////
    /// Deposits a coin into the bank and returns an NFT receipt.
    /// Aborts if the coin’s balance is zero.
    public fun deposit<T>(
        bank: &mut AssetBank,
        deposited_coin: coin::Coin<T>,
        ctx: &mut TxContext
    ): Receipt<T> {
        let amount = coin::value(&deposited_coin);
        if (amount == 0) {
            abort E_ZERO_DEPOSIT;
        };

        // Update bank counters.
        bank.deposit_count = bank.deposit_count + 1;
        bank.active_nft_count = bank.active_nft_count + 1;

        let depositor_addr = sender(ctx);

        // Create a receipt that “holds” the deposited coin.
        let receipt = Receipt<T> {
            id: object::new(ctx),
            deposit_id: bank.deposit_count,
            depositor: depositor_addr,
            amount: amount,
            coin: deposited_coin,
        };

        // Emit a deposit event.
        event::emit(DepositEvent {
            deposit_id: bank.deposit_count,
            depositor: depositor_addr,
            amount: amount,
        });

        receipt
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Withdraw Function
    ////////////////////////////////////////////////////////////////////////////////
    /// Withdraws the deposit by consuming the receipt and returning the deposited coin.
    /// Aborts if the caller is not the original depositor.
    public fun withdraw<T>(
        bank: &mut AssetBank,
        receipt: Receipt<T>,
        ctx: &mut TxContext
    ): (coin::Coin<T>, UID) {
        let caller = sender(ctx);
        if (caller != receipt.depositor) {
            abort E_NOT_DEPOSITOR;
        };

        bank.active_nft_count = bank.active_nft_count - 1;

        event::emit(WithdrawEvent {
            deposit_id: receipt.deposit_id,
            depositor: receipt.depositor,
            amount: receipt.amount,
        });

        // Destructure the receipt and return both the coin and the UID.
        let Receipt { id, deposit_id: _, depositor: _, amount: _, coin } = receipt;
        (coin, id)
    }
}
