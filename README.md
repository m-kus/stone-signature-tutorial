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

We will also need to initialize the storage of our verifier contract, which contains the hash of the `zkstark_signature` program.  
To compute the program hash we can use the tool provided by Integrity: https://integrity-hashes-calculator.vercel.app

Upload your proof (from `target/proof.json`) and copy the `progarm_hash`

> [!NOTE]
> Change `class-hash` according to the output on the declare step
> Change `constructor-calldata` according to the results from the calculator website

```sh
sncast deploy --fee-token eth --class-hash 0x45a88b588f1d25c66d524b59a43cebf9c0b493a06af5d687694da40d05b4f1e --constructor-calldata 0x2a98cb5fb03dabec9b3128e034f8a5297a8d7cfc44e382e2422ebf507875fbe
```

We have created a new instance of our contract class!

### Verifying ZKSTARK signature

Finally, we can verify that our signature is valid, given the public key and the message hash.  
Let's create an alias for our contract to reuse it in the future:

```sh
export SIG_VERIFIER_ADDRESS=0x6f5c47a9edbbc0a887c44e29670edcfa03b9da9a8067a3e64cf3c9e42f5ec5f
```

Now we are ready to call the contract, note that we are not creating an actual transaction — this is not necessary for our prototype.

```sh
sncast call --contract-address $SIG_VERIFIER_ADDRESS --function "is_signature_valid" --calldata "0x689991b0e36441c881b859cf67f4eba29d68fc172bb6be80ae1be6956bcf21f 0x2f0d8840bcf3bc629598d8a6cc80cb7c0d9e52d93dab244bbf9cd0dca0ad082"
```

## Notes

### Privacy
