# From https://github.com/dipdup-io/stone-packaging/blob/master/helpers/calculate_fri_step_list.py

import argparse
import json


def generate_params(fri_step_list) -> str:
    return {
        "field": "PrimeField0",
        "channel_hash": "poseidon3",
        "commitment_hash": "blake256_masked248_lsb",
        "n_verifier_friendly_commitment_layers": 10,
        "pow_hash": "blake256",
        "statement": {
            "page_hash": "pedersen"
        },
        "stark": {
            "fri": {
                "fri_step_list": fri_step_list,
                "last_layer_degree_bound": 128,
                "n_queries": 18,
                "proof_of_work_bits": 24
            },
            "log_n_cosets": 2
        },
        "use_extension_field": False,
        "verifier_friendly_channel_updates": True,
        "verifier_friendly_commitment_hash": "poseidon3"
    }


def calculate_fri_step_list(desired_degree_bound: int, last_layer_degree_bound: int) -> list:
    to_process = desired_degree_bound // last_layer_degree_bound

    def highest_power_of_2_in(n):
        power = 0
        
        while n % 2 == 0:
            n //= 2
            power += 1
            
        return power

    fri_step_list = []
    highest_power_of_2 = highest_power_of_2_in(to_process)

    while True:
        if highest_power_of_2 <= 4:
            fri_step_list.append(highest_power_of_2)
            break
        
        fri_step_list.append(4)
        highest_power_of_2 = highest_power_of_2 - 4

    return fri_step_list


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Stone prover parameters file")
    parser.add_argument(
        "--desired-degree-bound",
        dest="desired_degree_bound",
        type=int,
        help="The number that goes after STARK in cpu_air_prover error message",
    )
    parser.add_argument(
        "--last-layer-degree-bound",
        dest="last_layer_degree_bound",
        type=int,
        help="Parameters from stark->fri->last_layer_degree_bound in prover config",
    )
    args = parser.parse_args()
    fri_step_list = calculate_fri_step_list(args.desired_degree_bound, args.last_layer_degree_bound)
    print(json.dumps(generate_params(fri_step_list), indent=2))