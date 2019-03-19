#!/usr/bin/python3

if __name__ == "__main__":

    import argparse, json, sys, os

    sys.path.insert(0, os.path.realpath(os.path.join(os.path.pardir, "utils", "internal")))
    import utils
    from termcolor import colored

    parser = argparse.ArgumentParser(description="Start a node in the network with the given parameters.")

    parser.add_argument("--config-file", required=True, type=str, help="Path to the node configuration JSON file.")
    args = parser.parse_args()

    try:
        with open(os.path.realpath(args.config_file), "r") as config_json_file:
            try:
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
            except Exception as ex:
                print(colored(ex, "red"), file=sys.stderr)
                exit(1)
    except Exception as ex:
        print(colored(ex, "red"), file=sys.stderr)
        exit(2)

    node_directory = os.path.join(utils.get_containers_directory(), "node")

    docker_compose_file_path = os.path.join(node_directory, "docker-compose.yaml")
    docker_compose_env_file_path = os.path.join(node_directory, ".env")

    try:
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
    except Exception as ex:
        print(colored(ex, "red"), file=sys.stderr)
        exit(3)

    docker_compose_command = "docker-compose -f {0} up -d --remove-orphans".format(docker_compose_file_path)

    try:
        os.chdir(node_directory)            #Needed by docker-compose to read the .env file
    except Exception as ex:
        print(colored(ex, "red"), file=sys.stderr)
        exit(4)

    for (output, error) in utils.execute_asynchronous_cmd(docker_compose_command.split()):
        if output is not None:
            print(output, end="")
        else:
            print(colored(error, "red"), end="")
    
    try:
        os.remove(docker_compose_env_file_path)
    except:
        pass