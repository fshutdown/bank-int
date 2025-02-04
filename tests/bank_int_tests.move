module 0x1::bank_tests {
    use 0x1::bank;
    use sui::coin;
    use sui::coin::{TreasuryCap, Coin};
    use sui::object::{UID};
    use sui::tx_context::new_from_hint;

    #[test_only]
    use sui::test_scenario::{Self, next_tx, ctx};

    public struct BB_COIN has key, store, drop { id: u64}

    #[test]
    fun deposit_and_withdraw_sui_coin_test() : UID {
        let ctx = &mut new_from_hint(@0x1, 0, 0, 0, 0);
        let scenario = test_scenario::begin(@0x1);

        // Create a bank object for testing
        let mut bank_obj = bank::create_asset_bank(ctx);

        // Define coin and mint it
        let initial_balance = 1000;
        let witness: BB_COIN;
        witness = BB_COIN {id: object::new(ctx)};
        let (mut treasury_cap, metadata) = coin::create_currency(
            witness, 2, b"BBC", b"BeBeeCoin", b"The Bee coin", option::none(), ctx
        );

        transfer::public_freeze_object(metadata);

        let address = tx_context::sender(ctx);
        coin::mint_and_transfer(&mut treasury_cap, initial_balance, address, ctx);

        transfer::public_transfer(treasury_cap, address);
        let coin_obj = test_scenario::take_from_sender<Coin<BB_COIN>>(&scenario);

        // Make a deposit into the bank
        let receipt = bank::deposit(&mut bank_obj, coin_obj, ctx);

        // Assert bank state
        assert!(bank::deposit_count(&mut bank_obj) == 1, 100);
        assert!(bank::active_nft_count(&mut bank_obj) == 1, 101);

        // Withdraw funds
        let (mut withdrawn_coin, _receipt_uid) = bank::withdraw(&mut bank_obj, receipt, ctx);
        let withdrawn_amount = coin::value(&mut withdrawn_coin);

        // Assert bank state after withdrawal
        assert!(withdrawn_amount == initial_balance, 102);
        assert!(bank::active_nft_count(&mut bank_obj) == 0, 103);

        transfer::public_transfer(bank_obj, tx_context::sender(ctx));
        transfer::public_transfer(withdrawn_coin, tx_context::sender(ctx));

        test_scenario::end(scenario);

        _receipt_uid
    }
}
