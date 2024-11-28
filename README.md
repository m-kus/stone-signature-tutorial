# ZKSTARK signature

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

See https://stone-packaging.pages.dev/install/binaries

### Integrity serializer

Integrity is a set of Cairo contracts and a toolchain for recursive proving on Starknet.

```sh
cargo install --git https://github.com/m-kus/integrity-calldata-generator --rev e6206805dfe481cbd8f1fbf2629957ae505a8828 swiftness
```

## Tutorial

In this tutorial we will sign a message with our private key and then verify it onchain.

### Compile the programs

```
make build
```

### Get execution artifacts

```
make artifacts
```

### Generate proof

```
make prove
```

We can check that the proof is correct (locally):

```
make verify
```

### Serialize and split proof

```
make calldata
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

```
make register-fact
```

### Deploy signature verifier contract

Before deploing our contract we need to declare its class, i.e. "upload the code".

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

## Notes

### Privacy
