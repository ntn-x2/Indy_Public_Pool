#!/usr/bin/python3

if __name__ == "__main__":

    import argparse, sys, os, shutil
    from plenum.common.keygen_utils import initLocalKeys, initNodeKeysForBothStacks
    from plenum.common.util import hexToFriendly
    from stp_core.crypto.util import ed25519SkToCurve25519 as es2c, isHex, randomSeed
    from termcolor import colored

    sys.path.insert(0, os.path.realpath(os.path.join(os.path.pardir, "utils", "internal")))
    import utils

    parser = argparse.ArgumentParser(description="Generate keys for a TRUSTEE or a STEWARD by taking a name and an optional seed for the keys generation.")

    parser.add_argument("--name", required=True, type=str, help="Entity name, e.g., Trustee1.")
    parser.add_argument("--role", required=True, type=str, help="Entity name, e.g., TRUSTEE, STEWARD, NODE.")
    parser.add_argument("--seed", required=False, type=str, help="Seed for the key generation. Defaults to a random one.")
    parser.add_argument("--force", help="If true, new keys override the previous ones.", action="store_true")
    args = parser.parse_args()

    entity_keys_dir = os.path.join(utils.get_keys_directory(), args.name)
    logs_file = os.path.join(entity_keys_dir, "keys.out")

    if not os.path.exists(entity_keys_dir):
        utils.create_folder(entity_keys_dir, force=False)
    elif not args.force:
        answer = input("There seems to be keys associated with the current alias name. Want to proceed anyway? y to continue, anything else to interrupt the process.\n> ")
        if answer is not "y":
            print("Keys creation process interrupted.")
            exit()

    if args.role.upper() not in {"TRUSTEE", "STEWARD", "NODE"}:
        print(colored("Invalid role specified. Please select one of \"TRUSTEE\", \"STEWARD\" or \"NODE\"", "red"), file=sys.stderr)
        exit(1)

    is_node = args.role.upper() not in {"TRUSTEE", "STEWARD"}

    # Redirect output of called functions (base58-encoded pub and verkey) to a file, and then prints the content of the file.
    utils.clean_folder(entity_keys_dir)

    try:
        utils.set_output_verbosity(False)
        seed_to_use = args.seed or randomSeed()
        pub_key, verkey, bls_key, pop_bls_key = initLocalKeys(args.name, entity_keys_dir, seed_to_use, override=True, use_bls=False) if not is_node else initNodeKeysForBothStacks(args.name, entity_keys_dir, seed_to_use, override=True, use_bls=True)
        utils.set_output_verbosity(True)
    except Exception as keys_ex:
        utils.set_output_verbosity(True)
        shutil.rmtree(entity_keys_dir, ignore_errors=True)
        print(colored(keys_ex, "red"), file=sys.stderr)
        exit(2)

    seed_to_use = seed_to_use.decode("utf-8") if type(seed_to_use) is bytes else seed_to_use
    pub_key = hexToFriendly(pub_key)
    verkey = hexToFriendly(verkey)

    try:
        with open(logs_file, "w+") as logs_file_opened:
            logs_file_opened.seek(0)
            logs_file_opened.write("Name: \t\t\t\t\t\t\t{}\n".format(args.name))
            logs_file_opened.write("Public key: \t\t\t\t\t{}\n".format(pub_key))
            logs_file_opened.write("Verification key: \t\t\t\t{}\n".format(verkey))
            if is_node:
                logs_file_opened.write("BLS key: \t\t\t\t\t\t{}\n".format(bls_key))
                logs_file_opened.write("BLS key proof-of-possession: \t{}\n".format(pop_bls_key))
    except Exception as ex:
        print(colored(ex, "red"), file=sys.stderr)
        exit(3)
            
    print(colored("Seed used: \t\t{}".format(seed_to_use), "green"))
    print("Public key: \t\t{}".format(pub_key))
    print("Verification key: \t{}".format(verkey))