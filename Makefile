build:
	scarb build

dryrun:
	cairo1-run target/dev/zkstark_signature.sierra.json --layout recursive_with_poseidon --args '[42 1 2 3]' --print_output

artifacts:
	cairo1-run target/dev/zkstark_signature.sierra.json --layout recursive_with_poseidon --args '[42 1 2 3]' --proof_mode --air_public_input target/public_input.json --air_private_input target/private_input.json --trace_file target/trace --memory_file target/memory

params:
	python scripts/generate_params.py --desired-degree-bound ${BOUND} --last-layer-degree-bound 128 > prover_params.json

prove:
	time cpu_air_prover --parameter_file prover_params.json --prover_config_file prover_config.json --private_input_file target/private_input.json --public_input_file target/public_input.json --out_file target/proof.json --generate_annotations true

verify:
	cpu_air_verifier --in_file target/proof.json && echo "Proof is valid!"

calldata:
	rm -rf ./target/calldata
	mkdir ./target/calldata
	# see https://github.com/HerodotusDev/integrity/blob/main/deployed_contracts.md
	echo "0x16409cfef9b6c3e6002133b61c59d09484594b37b8e4daef7dcba5495a0ef1a" > ./target/calldata/contract_address
	swiftness --proof target/proof.json --layout recursive_with_poseidon --hasher keccak_160_lsb --stone-version stone6 --out target/calldata

register-fact:
	JOB_ID=$$((RANDOM % 10000 + 1)); \
	echo "Job $$JOB_ID"; \
	./scripts/register_fact.sh $$JOB_ID recursive_with_poseidon keccak_160_lsb stone6 cairo1
