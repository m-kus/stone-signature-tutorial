//! This contract checks that our zkstark signature is valid

#[starknet::interface]
pub trait ISigVerifier<TContractState> {
    /// Given the previously registered proof fact (via Integrity) check that the proof was
    /// generated for the expected program hash, expected message hash, and the private key
    /// that was used for signing corresponds to the expected public key.
    fn is_signature_valid(
        self: @TContractState, public_key: felt252, message_hash: felt252
    ) -> bool;
}

#[starknet::contract]
mod SigVerifier {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use integrity::{Integrity, IntegrityWithConfig, calculate_fact_hash, VerifierConfiguration};

    const SECURITY_BITS: u32 = 96;

    #[storage]
    struct Storage {
        /// Hash of the zkstark_signature program
        program_hash: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, program_hash: felt252) {
        self.program_hash.write(program_hash);
    }

    #[abi(embed_v0)]
    impl SigVerifierImpl of super::ISigVerifier<ContractState> {
        fn is_signature_valid(
            self: @ContractState, public_key: felt252, message_hash: felt252
        ) -> bool {
            // Note that we prepended two felts to the output: this is serde encoding for array
            let output = [0x0, 0x2, public_key, message_hash].span();
            let fact_hash = calculate_fact_hash(
                self.program_hash.read(), output,
            );
            let config = VerifierConfiguration {
                layout: 'recursive_with_poseidon',
                hasher: 'keccak_160_lsb',
                stone_version: 'stone6',
                memory_verification: 'cairo1',
            };
            // Integrity already contains default proxy/fact registry contract addresses for testnet
            let integrity = Integrity::new().with_config(config, SECURITY_BITS);
            integrity.is_fact_hash_valid(fact_hash)
        }
    }
}
