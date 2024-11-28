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

```sh
cargo install --git https://github.com/lambdaclass/cairo-vm cairo1-run
```

### Stone prover

See https://stone-packaging.pages.dev/install/binaries

### Integrity serializer

```sh
cargo install --git https://github.com/m-kus/integrity-calldata-generator --rev e6206805dfe481cbd8f1fbf2629957ae505a8828 swiftness
```

## Tutorial

### Compile the program

```
make build
```

### Get execution artifacts

```
make artifacts
```

### Generate proof

```
make proof
```

### Serialize and split proof

```
make calldata
```

### Create and top up testnet account

### Verify proof on Starknet

```
make register-fact
```
