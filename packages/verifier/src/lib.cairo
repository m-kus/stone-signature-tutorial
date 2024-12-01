//! This contract checks that our zkstark signature is valid

#[starknet::interface]
pub trait ISigVerifier<TContractState> {
    /// Given the previously registered proof fact (via Integrity) check that the proof was
    /// generated for the expected program hash, expected message hash, and the private key
    /// that was used for signing corresponds to the expected public key.
    fn is_signature_valid(
        self: @TContractState, program_hash: felt252, public_key: felt252, message_hash: felt252
    ) -> bool;
}

#[starknet::contract]
mod SigVerifier {
    use integrity::{Integrity, IntegrityWithConfig, calculate_fact_hash, VerifierConfiguration};

    const SECURITY_BITS: u32 = 96;

    #[storage]
    struct Storage {
        // Empty storage
    }

    #[abi(embed_v0)]
    impl SigVerifierImpl of super::ISigVerifier<ContractState> {
        fn is_signature_valid(
            self: @ContractState, program_hash: felt252, public_key: felt252, message_hash: felt252
        ) -> bool {
            // Note that we prepended and appended some felts to the output:
            //   - prefix is the serde encoding of the output array
            //   - suffix is the program input that is concatenated with the output
            //     (cairo1-run issue, see notes on privacy in the README)
            let output = [0x0, 0x2, public_key, message_hash, 0x4, 0x2a, 0x1, 0x2, 0x3].span();
            let fact_hash = calculate_fact_hash(
                program_hash, output,
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

#[cfg(test)]
mod tests {
    #[test]
    fn test_signature_verification() {
        // TODO: Implement test for verifying the signature with mocked fact registry contract
    }
}
