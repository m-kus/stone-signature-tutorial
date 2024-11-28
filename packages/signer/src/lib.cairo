use core::hash::{HashStateTrait, HashStateExTrait};
use core::poseidon::PoseidonTrait;

/// Takes private key (single felt) and a message (the rest of the felts)
/// returns public key (hash of the private key) and message hash.
/// Uses Poseidon for hashing.
fn main(mut args: Array<felt252>) -> Array<felt252> {
    let private_key = args.pop_front().unwrap();
    let public_key = PoseidonTrait::new().update_with(private_key).finalize();

    let mut hasher = PoseidonTrait::new();
    while let Option::Some(elt) = args.pop_front() {
        hasher = hasher.update_with(elt);
    };
    let message_hash = hasher.finalize();

    array![public_key, message_hash]
}
