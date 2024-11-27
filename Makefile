dryrun:
	cairo1-run target/dev/zkstark_signature.sierra.json --layout recursive_with_poseidon --args '[42 1 2 3]' --print_output

artifacts:
	cairo1-run target/dev/zkstark_signature.sierra.json --layout recursive_with_poseidon --args '[42 1 2 3]' --proof_mode --air_public_input target/public_input.json --air_private_input target/private_input.json --trace_file target/trace --memory_file target/memory

params:
	python scripts/generate_params.py --desired-degree-bound ${BOUND} --last-layer-degree-bound 128 > prover_params.json

prove:
	time cpu_air_prover --parameter_file prover_params.json --prover_config_file prover_config.json --private_input_file target/private_input.json --public_input_file target/public_input.json --out_file target/proof.json --generate_annotations true

verify-stone:
	cpu_air_verifier --in_file target/proof.json && echo "Proof is valid!"

calldata:
	proof_serializer < target/proof.json > target/calldata
