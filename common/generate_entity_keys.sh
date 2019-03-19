#!/usr/bin/python3

if __name__ == "__main__":

    import argparse, sys, os, shutil
    from plenum.common.keygen_utils import initLocalKeys

    sys.path.insert(0, os.path.realpath(os.path.join(os.path.pardir, "utils", "internal")))
    import utils

    parser = argparse.ArgumentParser(description="Generate keys for a TRUSTEE or a STEWARD by taking a name and an optional seed for the keys generation.")

    parser.add_argument("--name", required=True, type=str, help="Entity name, e.g., Trustee1.")
    parser.add_argument("--seed", required=False, type=str, help="Seed for the key generation. Defaults to a random one.")
    parser.add_argument("--force", help="If true, new keys override the previous ones.", action="store_true")
    args = parser.parse_args()

    entity_keys_dir = os.path.join(utils.get_keys_directory(), args.name)
    logs_file = os.path.join(entity_keys_dir, "base58_keys.out")

    if not os.path.exists(entity_keys_dir):
        utils.create_folder(entity_keys_dir, force=False)
    elif not args.force:
        answer = input("There seems to be keys associated with the current alias name. Want to proceed anyway? y to continue, anything else to interrupt the process.\n> ")
        if answer is not "y":
            print("Keys creation process interrupted.")
            exit()
        else:
            utils.create_folder(entity_keys_dir, force=True)

    # Redirect output of called functions (base58-encoded pub and verkey) to a file, and then prints the content of the file.
    try:
        utils.clean_folder(entity_keys_dir)
        with open(logs_file, "w+") as logs_file_opened:
            with utils.stdout_redirect(logs_file_opened) as file_stdout:
                initLocalKeys(args.name, entity_keys_dir, args.seed, override=True, use_bls=False)
            logs_file_opened.seek(0)
            print(logs_file_opened.read())
    except Exception as ex:
        shutil.rmtree(entity_keys_dir, ignore_errors=True)
        print(ex, file=sys.stderr)
        exit(1)