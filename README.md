# ZKSTARK signature

This is a simple Cairo1 implementation of a variation of [Ziggy](https://github.com/starkware-libs/ethSTARK/tree/ziggy?tab=readme-ov-file#11-ziggy) — a Post-Quantum-Secure signature scheme based on a ZK-STARK. It is not secure due to the specifics of the Cairo runner and Stone prover (see notes) nor it is practical due to the large proof size.  

The main purpose of the project is to showcase the current state of the proving stack and provide a step by step guide for people who are interested in using Cairo as a generic provable language.

## Installation

### Scarb

Scarb is a Cairo package and compiler toolchain manager.

The quickest installation option is:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
```

See more options in the [docs](https://docs.swmansion.com/scarb/download.html)

### Foundry

Starknet Foundry is a toolchain for developing smart contracts for Starknet.

Make sure you have [Rust](https://www.rust-lang.org/tools/install) installed!

```sh
curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh
```

And then run:

```sh
snfoundryup
```

### Cairo runner

Cairo runner is an interpreter that produces all the necessary artifacts for the proving.

```sh
cargo install --git https://github.com/lambdaclass/cairo-vm cairo1-run
```

### Stone prover

STARK One is the most battle tested prover out there, used in production for more than 3 years by Starknet and multiple StarkEx validiums (appchains).

See https://stone-packaging.pages.dev/install/binaries

### Integrity serializer

Integrity is a set of Cairo contracts and a toolchain for recursive proving on Starknet.

```sh
cargo install --git https://github.com/m-kus/integrity-calldata-generator --rev e6206805dfe481cbd8f1fbf2629957ae505a8828 swiftness
```

## Tutorial

In this step-by-step guide we will sign a message with our private key and then verify it in various ways.

### Build the signer program

First we need to compile the program that produces zkstark signatures, we do that with a specific `cairo1-run` profile which is suitable for running in proof mode.

```
scarb --profile cairo1-run build --package zkstark_signature
```

### Run and get execution artifacts

Now we can use `cairo1-run` runner to produce execution trace, we just need to provide the compiled program (Sierra file) and serialized arguments — 4 field elements, where first felt is the private key, and the rest are the message.

```
cairo1-run target/cairo1-run/zkstark_signature.sierra.json \
    --layout recursive_with_poseidon \
    --args '[42 1 2 3]' \
    --proof_mode \
    --air_public_input target/public_input.json \
    --air_private_input target/private_input.json \
    --trace_file target/trace \
    --memory_file target/memory
```

### Generate proof

Given the execution artifacts and predefined prover configuration (see https://stone-packaging.pages.dev/usage/configuration for more information) we can generate a STARK proof for this concrete program invocation.

```
cpu_air_prover \
    --parameter_file prover_params.json \
    --prover_config_file prover_config.json \
    --private_input_file target/private_input.json \
    --public_input_file target/public_input.json \
    --out_file target/proof.json \
    --generate_annotations true
```

We can check that the proof is correct (locally):

```
cpu_air_verifier --in_file target/proof.json && echo "Proof is valid!"
```

### Serialize and split the proof

The obtained proof is pretty large and it's serialized in JSON, which is not suitable for submitting onchain. So before all we need to encode the proof data and split into several digestible parts so that we remain within gas limits for every submitted transaction. Swiftness utility does exactly that, we should provide some extra parameters to specify the proving options we use: layout (set of builtins), commitment hash function, and prover version.

```
rm -rf ./target/calldata
mkdir ./target/calldata

# see https://github.com/HerodotusDev/integrity/blob/main/deployed_contracts.md
echo "0x16409cfef9b6c3e6002133b61c59d09484594b37b8e4daef7dcba5495a0ef1a" > ./target/calldata/contract_address

swiftness --proof target/proof.json \
    --layout recursive_with_poseidon \
    --hasher keccak_160_lsb \
    --stone-version stone6 \
    --out target/calldata
```

### Create and top up testnet account

This command will generate an address for our `test` account contract (using a predefined AA wallet):

```sh
sncast account create
```

It's not deployed yet, we need to send some money to this address first.

Use the faucet https://blastapi.io/faucets/starknet-sepolia-eth for sending tokens to the generated address.

> [!WARNING]  
> Some faucets do not correctly handle addresses with leading zeros stripped, if you see "Invalid address" error, just add a zero after '0x'

Once the balance is not zero we can deploy the account:

```sh
sncast account deploy --fee-token eth
```

### Verify proof on Starknet

Now we can verify the split proof on Starket using Integrity contracts. We need to provide a unique job ID so that the verifier contract can keep track of the multiple submissions.

```
JOB_ID=$((RANDOM % 10000 + 1)) && ./scripts/register_fact.sh $JOB_ID recursive_with_poseidon keccak_160_lsb stone6 cairo1
```

### Check the verification fact

Once the proof is verified we should be able to query the status of the verification fact. In order to do that we need to calculate the fact ID which is a hash of the program and execution output. Integrity provides a nice visual tool where you can upload your proof and get the fact hash: https://integrity-hashes-calculator.vercel.app/

Then we can go to the explorer, open the fact registry contract (there is a separate contract for each proving configuration, check here https://github.com/HerodotusDev/integrity/blob/main/deployed_contracts.md) and navigate to the "Read Contract" tab.

For example:
- Open https://sepolia.voyager.online/contract/0x16409cfef9b6c3e6002133b61c59d09484594b37b8e4daef7dcba5495a0ef1a#readContract
- The fact hash is `0x6d9ec29a2511b606d75d1094b0719d2af6136e0ac89d214e1b0a18a711fb562`
- Query `get_all_verifications_for_fact_hash`

We will see
```json
[
    {
        "verification_hash": "0x0606d88e8e6983c4d6f31006c376ea3d890a2c32849420440f8e72023c314a2f",
        "security_bits": "0x3c",
        "verifier_config": {
            "layout": "0x7265637572736976655f776974685f706f736569646f6e",
            "hasher": "0x6b656363616b5f3136305f6c7362",
            "stone_version": "0x73746f6e6536",
            "memory_verification": "0x636169726f31"
        }
    }
]
```

### Deploy signature verifier contract

To use the verification fact onchain we need to deploy a contract that would interact with the fact registry. Here and after we will call it "signature verifier". Before deploing our contract we need to declare its class, i.e. "upload the code".

> [!NOTE]
> Here `SigVerifier` is the name of our module behind the `#[starknet::contract]` attribute

```sh
sncast declare --package verifier_contract --fee-token eth --contract-name SigVerifier
```

> [!NOTE]
> Change `class-hash` according to the output on the declare step
> The contract has no constructor, so no calldata needed

```sh
sncast deploy --fee-token eth --class-hash 0x75d190387f0353a578693dfeca5f907731a3df27180857f6ad76c4260f808f
```

We have created a new instance of our contract class!

### Verifying ZKSTARK signature

Finally, we can verify that our signature is valid, given the public key and the message hash.  
Let's create an alias for our contract to reuse it in the future:

```sh
export SIG_VERIFIER_ADDRESS=0x20aefd2a80283ed39ccbfcf8ac0ccace54c52c94dd4106a63814c7df71071fd
```

We need to prepare `is_signature_valid` arguments which are: `program_hash`, `public_key`, and `message_hash`.  
To obtain the `program_hash` we can use the tool provided by Integrity: https://integrity-hashes-calculator.vercel.app

Upload your proof from `target/proof.json` and copy the `program_hash`.

```sh
sncast call --contract-address $SIG_VERIFIER_ADDRESS --function "is_signature_valid" --calldata "0x28270ace6de6dd53f39e33f0637cee54ff94019885e253661a9d5dc0b9045aa 0x689991b0e36441c881b859cf67f4eba29d68fc172bb6be80ae1be6956bcf21f 0x2f0d8840bcf3bc629598d8a6cc80cb7c0d9e52d93dab244bbf9cd0dca0ad082"
```

Now we are ready to call the contract, note that we are not creating an actual transaction — this is not necessary for our prototype.

## Notes on privacy

1. `cairo1-run` runner copies all inputs to the output segment which leads to the privacy leak. This is a known issue, which is resolved with the new version of `cairo-lang-runner` that is able to produce execution trace (for proving).
2. Proofs that are generated with Stone leak some bits of the trace because polynomial randomization is not implemented. Read more in https://github.com/starkware-libs/stone-prover/issues/8#issuecomment-1766480334 also https://eprint.iacr.org/2024/1037