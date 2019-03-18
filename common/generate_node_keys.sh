#!/usr/bin/python3

import contextlib, sys

@contextlib.contextmanager
def stdout_redirect(where):
    sys.stdout = where
    try:
        yield where
    finally:
        sys.stdout = sys.__stdout__

import os, shutil

def delete_all_content(folder_path):
    for file in os.listdir(folder_path):
        file_path = os.path.join(folder_path, file)
        if os.path.isfile(file_path):
            os.unlink(file_path)
        elif os.path.isdir(file_path):
            shutil.rmtree(file_path, ignore_errors=True)


if __name__ == "__main__":

    import argparse
    from plenum.common.keygen_utils import initNodeKeysForBothStacks

    parser = argparse.ArgumentParser(description="Generate keys for a TRUSTEE or a STEWARD by taking a name and an optional seed for the keys generation.")

    parser.add_argument("--name", required=True, type=str, help="Entity name, e.g., Trustee1.")
    parser.add_argument("--seed", required=False, type=str, help="Seed for the key generation. Defaults to a random one.")
    parser.add_argument("--force", help="If true, new keys override the previous ones.", action="store_true")
    args = parser.parse_args()

    current_directory = os.path.join(os.path.realpath(__file__), os.pardir)
    parent_directory = os.path.realpath(os.path.join(current_directory, os.pardir))

    keys_dir = os.path.join(parent_directory, "keys")
    entity_keys_dir = os.path.join(keys_dir, args.name)
    logs_file = os.path.join(entity_keys_dir, "base58_keys.out")

    if not os.path.exists(entity_keys_dir):
        os.makedirs(entity_keys_dir)
    elif not args.force:
        answer = input("There seems to be keys associated with the current alias name. Want to proceed anyway? y to continue, anything else to interrupt the process.\n> ")
        if answer is not "y":
            print("Keys creation process interrupted.")
            exit()
    
    try:
        delete_all_content(entity_keys_dir)
        with open(logs_file, "w") as logs_file_opened, stdout_redirect(logs_file_opened) as file_stdout:
            initNodeKeysForBothStacks(args.name, entity_keys_dir, args.seed, override=True, use_bls=True)

        with open(logs_file, "r+") as logs_file_opened:
            def should_consider_line(line, row):
                print(line, end="")
                return row > 4 and (line.startswith("Public") or line.startswith("Verification") or line.startswith("BLS Public") or line.startswith("Proof of possession for BLS"))

            filtered_output = [line for (index, line) in enumerate(logs_file_opened.readlines()) if should_consider_line(line, index)]

            logs_file_opened.seek(0)
            logs_file_opened.write("".join(filtered_output))
            logs_file_opened.truncate()
    except Exception as ex:
        shutil.rmtree(entity_keys_dir, ignore_errors=True)
        print(ex, file=sys.stderr)
        exit()