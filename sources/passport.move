module pub_addr::passport{
    use std::error;
    use std::string;
    use std::vector;
    use aptos_token::token;
    use std::signer;
    use std::string::String;
    use aptos_token::token::TokenDataId;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::resource_account;
    use aptos_framework::account;

    struct ModuleData has key {
        signer_cap: SignerCapability,
        token_data_id: TokenDataId,
        minting_enabled: bool,
    }

    const ENOT_AUTHORIZED: u64 = 1;

    fun init_module(resource_signer: &signer){
        let collection_name = string::utf8(b"Ambassador Passport Collection");
        let description = string::utf8(b"Ambassador Passport description");
        let collection_uri = string::utf8(b"Ambassador Passport uri");
        let token_name = string::utf8(b"Ambassador Passport");
        let token_uri = string::utf8(b"Ambassador Passport Token uri");

        let maximum_supply = 0;
        let mutate_setting = vector<bool>[ false, false, false ];

        token::create_collection(resource_signer, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        let token_data_id = token::create_tokendata(
            resource_signer,
            collection_name,
            token_name,
            string::utf8(b"It`s Ambassador Passport :)"),
            0,
            token_uri,
            signer::address_of(resource_signer),
            1,
            0,
            token::create_token_mutability_config(
                &vector<bool>[ false, false, false, false, true ]
            ),
            vector<String>[string::utf8(b"tier"), string::utf8(b"track")],
            vector<vector<u8>>[b"", b""],
            vector<String>[string::utf8(b"u8"), string::utf8(b"u8")],
        );

        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @source_addr);
        move_to(resource_signer, ModuleData {
            signer_cap: resource_signer_cap,
            token_data_id,
            minting_enabled: false,
        });
    }

    public entry fun mint_passport(receiver: &signer, to_address: address, tier: u8, track: u8) acquires ModuleData {

        let caller_address = signer::address_of(receiver);
        assert!(caller_address == @admin_addr, error::permission_denied(ENOT_AUTHORIZED));

        let module_data = borrow_global_mut<ModuleData>(@pub_addr);

        let resource_signer = account::create_signer_with_capability(&module_data.signer_cap);
        let token_id = token::mint_token(&resource_signer, module_data.token_data_id, 2);
        let (creator_address, collection, name) = token::get_token_data_id_fields(&module_data.token_data_id);

        token::transfer(
            &resource_signer, 
            token_id,
            to_address, 
            1);

        token::mutate_token_properties(
            &resource_signer,
            to_address,
            creator_address,
            collection,
            name,
            0,
            1,
            vector<String>[string::utf8(b"tier"), string::utf8(b"track")],
            vector<vector<u8>>[vector[tier], vector[track]],
            vector<String>[string::utf8(b"u8"), string::utf8(b"u8")],
        );
    }
}