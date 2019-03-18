#!/usr/bin/python3

if __name__ == "__main__":

    import argparse
    
    parser = argparse.ArgumentParser(description="Generate keys for a TRUSTEE or a STEWARD by taking a name and an optional seed for the keys generation.")

    parser.add_argument("--name", required=True, type=str, help="Entity name, e.g., Trustee1.")
    parser.add_argument("--seed", required=False, type=str, help="Seed for the key generation. Defaults to a random one.")
    parser.add_argument("--force", help="If true, new keys override the previous ones.", action="store_true")
    args = parser.parse_args()
    
    import os

    current_directory = os.path.realpath(os.path.join(os.path.realpath(__file__), os.pardir))
    pool_config_file = os.path.join(current_directory, "pool_config.json")
    pool_transaction_file_path = os.path.join(current_directory, "pool_transactions_genesis")
    domain_transaction_file_path  = os.path.join(current_directory, "domain_transactions_genesis")

    # Read json config file
    with open(pool_config_file, "r") as pool_config:
        # Parse config files
        import json
        
        pool_config_json = json.load(pool_config)

        domain_info = pool_config_json["domain"]
        nym_entities_transactions = []

        for index, d_info in enumerate(domain_info):
            d_alias = d_info.get("alias", None)
            d_did = d_info["did"]
            d_verkey = d_info["verkey"]
            d_role = d_info["role"]
            d_creator = d_info.get("creator", None)
            nym_transaction_payload = {"dest": d_did, "role": "0" if d_role == "TRUSTEE" else "2", "verkey": d_verkey}
            if d_alias is not None:
                nym_transaction_payload["alias"] = d_alias
            nym_transaction = {"reqSignature": {}, "txn": {"data": nym_transaction_payload, "metadata": {} if d_creator is None else {"from": d_creator}, "type": "1"}, "txnMetadata": {"seqNo": index+1}, "ver": "1"}
            
        pool_info = pool_config_json["pool"]
        node_entities_transactions = []

        import re
        from hashlib import sha256

        for index, p_info in enumerate(pool_info):
            p_alias = p_info["alias"]
            p_keys_folder = p_info["keys_folder"]
            p_ip = p_info["ip"]
            p_node_port = p_info["node_port"]
            p_client_port = p_info["client_port"]
            p_steward_did = p_info["steward_did"]

            keys_folder_path = os.path.realpath(p_keys_folder)

            node_server_keys_friendly_output = os.path.join(keys_folder_path, "base58_keys.out")

            with open(node_server_keys_friendly_output, "r") as node_keys:
                for (n_index, line) in enumerate(node_keys.read().splitlines()):
                    if line.startswith("Verification key"):
                        ver_key = line.split(" ")[3]
                    elif line.startswith("Public key"):
                        pub_key = line.split(" ")[3]
                    elif line.startswith("BLS Public key"):
                        bls_key = line.split(" ")[4]
                    elif line.startswith("Proof of possession for BLS key"):
                        pop_bls_key = line.split(" ")[7]
                node_transaction = {"reqSignature": {}, "txn": {"data": {"data": {"alias": p_alias, "blskey": bls_key, "blskey_pop": pop_bls_key, "client_ip": p_ip, "client_port": p_client_port, "node_ip": p_ip, "node_port": p_node_port, "services": ["VALIDATOR"]}, "dest": ver_key}, "type": "0"}, "txnMetadata": {"seqNo": n_index+1, "txnId": sha256(p_alias.encode()).hexdigest()}, "ver": "1"}
                if p_steward_did is not None:
                    node_transaction["txn"]["metadata"] = {"from": p_steward_did}
                node_entities_transactions.append(node_transaction)
        
        with open(domain_transaction_file_path, "w") as domain_transactions:
            for nym_transaction in nym_entities_transactions:
                domain_transactions.write(json.dumps(nym_transaction) + "\n")
        
        with open(pool_transaction_file_path, "w") as pool_transactions:
            for node_transaction in node_entities_transactions:
                pool_transactions.write(json.dumps(node_transaction) + "\n" )