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
Once the balance is not zero we can deploy the account:

```sh
sncast account deploy -fee-token eth
```

### Verify proof on Starknet

```
make register-fact
```

## Notes

### Privacy
