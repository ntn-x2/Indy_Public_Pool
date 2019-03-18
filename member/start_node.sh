#!/usr/bin/python3

if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser(description="Start a node in the network with the given parameters.")

    parser.add_argument("--config-file", required=True, type=str, help="Path to the node configuration JSON file.")
    args = parser.parse_args()

    import json, sys, os

    try:
        with open(os.path.realpath(args.config_file), "r") as config_json_file:
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

    current_directory = os.path.join(os.path.realpath(__file__), os.pardir)
    parent_directory = os.path.realpath(os.path.join(current_directory, os.pardir))
    node_directory = os.path.join(parent_directory, "containers", "node")

    docker_compose_file_path = os.path.join(node_directory, "docker-compose.yaml")
    docker_compose_env_file_path = os.path.join(node_directory, ".env")

    with open(docker_compose_env_file_path, "w") as docker_env_file:
        docker_env_file.write("LOGS_MOUNT_POINT={}\n".format(os.path.realpath(log_out_directory)))
        docker_env_file.write("LEDGER_MOUNT_POINT={}\n".format(os.path.realpath(ledger_out_directory)))
        docker_env_file.write("KEYS_PATH={}\n".format(os.path.realpath(keys_in_directory)))
        docker_env_file.write("NODE_ALIAS={}\n".format(node_alias))
        docker_env_file.write("NODE_SERVER_PORT={}\n".format(node_server_port))
        docker_env_file.write("NODE_CLIENT_PORT={}\n".format(node_client_port))
        docker_env_file.write("NETWORK_NAME={}\n".format(network_name))
        docker_env_file.write("POOL_GENESIS={}\n".format(os.path.realpath(pool_genesis_file)))
        docker_env_file.write("DOMAIN_GENESIS={}".format(os.path.realpath(domain_genesis_file)))

    docker_compose_command = "docker-compose -f {0} up -d --remove-orphans".format(docker_compose_file_path)

    os.chdir(node_directory)

    import subprocess

    def execute(cmd):
        popen = subprocess.Popen(cmd, stdout=subprocess.PIPE, universal_newlines=True)
        for stdout_line in iter(popen.stdout.readline, ""):
            yield (stdout_line, None) 
        popen.stdout.close()
        return_code = popen.wait()
        if return_code:
            yield (None, subprocess.CalledProcessError(return_code, cmd))

    for (output, error) in execute(docker_compose_command.split()):
        if output is not None:
            print(output, end="")
        else:
            print(error, end="")

    # print("Output: {}".format(output))
    # print("Error: {}".format(error))