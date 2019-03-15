#!/usr/bin/python3

if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser(description="Start a node in the network with the given parameters.")

    parser.add_argument("--config-file", required=True, type=str, help="Path to the node configuration JSON file.")
    args = parser.parse_args()

    import json, sys

    try:
        with open(args.config_file, "r") as config_json_file:
            config_json = json.load(config_json_file)

            node_info = config_json["node"]
            node_alias = node_info["alias"]
            node_server_port = node_info["node_port"]
            node_client_port = node_info["client_port"]
            network_name = node_info["network"]

            bind_info = config_json["binding"]
            log_out_directory = bind_info["log_out"]
            ledger_out_directory = bind_info["ledger_out"]
            keys_in_directory = bind_info["keys_in"]
            pool_genesis_file = bind_info["pool_genesis_in"]
            domain_genesis_file = bind_info["domain_genesis_in"]
    except Exception as e:
        print(e, file=sys.stderr)
        exit()

    import os

    current_directory = os.path.realpath(os.path.join(os.path.realpath(__file__), os.pardir))
    parent_directory = os.path.realpath(os.path.join(current_directory, os.pardir))

    docker_compose_file_path = os.path.join(parent_directory, "containers", "node", "docker-compose.yaml")

    os.environ["LOGS_MOUNT_POINT"] = log_out_directory
    os.environ["LEDGER_MOUNT_POINT"] = ledger_out_directory
    os.environ["KEYS_PATH"] = keys_in_directory
    os.environ["NODE_ALIAS"] = node_alias
    os.environ["NODE_SERVER_PORT"] = str(node_server_port)
    os.environ["NODE_CLIENT_PORT"] = str(node_client_port)
    os.environ["NETWORK_NAME"] = network_name
    os.environ["POOL_GENESIS"] = pool_genesis_file
    os.environ["DOMAIN_GENESIS"] = domain_genesis_file

    docker_compose_command = "docker-compose -f {0} up -d".format(docker_compose_file_path)

    # print(docker_compose_command)
    # print(os.environ)

    import subprocess

    process = subprocess.Popen(docker_compose_command.split(), stdout=subprocess.PIPE)
    output, error = process.communicate()

    print("Output: {}".format(output))
    print("Error: {}".format(error))