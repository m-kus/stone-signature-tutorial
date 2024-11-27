use integrity::settings::VerifierSettings;
use integrity::{deserialization::stark::StarkProofWithSerde, stark::{StarkProof, StarkProofImpl},};


fn main(mut serialized: Span<felt252>, settings: @VerifierSettings) -> (felt252, felt252) {
    let stark_proof_serde = Serde::<StarkProofWithSerde>::deserialize(ref serialized).unwrap();
    let stark_proof: StarkProof = stark_proof_serde.into();

    let security_bits = stark_proof
        .verify(ContractAddressZero::zero(), ContractAddressZero::zero(), settings);
    assert(security_bits >= SECURITY_BITS, 'Security bits are too low');

    let (program_hash, output_hash) = match (*settings).memory_verification {
        0 => stark_proof.public_input.verify_strict(),
        1 => stark_proof.public_input.verify_relaxed(),
        2 => stark_proof.public_input.verify_cairo1(),
        _ => {
            assert(false, 'invalid memory_verification');
            (0, 0)
        }
    };

    (program_hash, output_hash)
}