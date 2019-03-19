import contextlib
@contextlib.contextmanager
def stdout_redirect(location):
    import sys 

    sys.stdout = location
    try:
        yield location
    finally:
        sys.stdout = sys.__stdout__

def execute_asynchronous_cmd(cmd):
    import subprocess

    popen = subprocess.Popen(cmd, stdout=subprocess.PIPE, universal_newlines=True)
    for stdout_line in iter(popen.stdout.readline, ""):
        yield (stdout_line, None)
    popen.stdout.close()
    return_code = popen.wait()
    if return_code:
        yield (None, subprocess.CalledProcessError(return_code, cmd))

def delete_all_content(folder_path):
    import os, shutil

    for file in os.listdir(folder_path):
        file_path = os.path.join(folder_path, file)
        if os.path.isfile(file_path):
            os.unlink(file_path)
        elif os.path.isdir(file_path):
            shutil.rmtree(file_path, ignore_errors=True)

def get_path_for_parent_directory(file_path):
    import os

    return os.path.realpath(os.path.join(os.path.realpath(file_path), os.pardir))

def create_folder(path, force=False):
    import os, shutil

    if os.path.exists(path) and force:
        shutil.rmtree(path)

    os.makedirs(path)

def clean_folder(path):
    import os, shutil

    for file in os.listdir(path):
        file_path = os.path.join(path, file)
        if os.path.isfile(file_path):
            os.unlink(file_path)
        elif os.path.isdir(file_path):
            shutil.rmtree(file_path, ignore_errors=True)

# Helpers for path-related operations

def _get_root_directory():
    import os

    return os.path.realpath(os.path.join(get_path_for_parent_directory(__file__), os.pardir, os.pardir))

def get_common_directory():
    import os

    return os.path.realpath(os.path.join(_get_root_directory(), "common"))

def get_containers_directory():
    import os

    return os.path.realpath(os.path.join(_get_root_directory(), "containers"))

def get_creator_directory():
    import os

    return os.path.realpath(os.path.join(_get_root_directory(), "creator"))

def get_keys_directory():
    import os

    return os.path.realpath(os.path.join(_get_root_directory(), "keys"))

def get_member_directory():
    import os

    return os.path.realpath(os.path.join(_get_root_directory(), "member"))