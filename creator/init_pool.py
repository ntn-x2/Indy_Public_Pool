import sys

# Read json config file
try:
    pool_config_file = open("pool_config.json")
except FileNotFoundError as e:
    print(e, file=sys.stderr)
    sys.exit(1)

# Parse config files
import json 
try:
    pool_config_json = json.load(pool_config_file)
except Exception as e:
    print(e, file=sys.stderr)
    sys.exit(2)

try:
    # Error generated here...
    pool_entities = parseConfigJSON(pool_config_json)
except:
    print("Pool config wrongly formatted.", file=sys.stderr)
    sys.exit(3)

def parseConfigJSON(json) -> []:
    if not isinstance(json, list) or len(json) < 1:
        raise ValueError
    
    for pool_entity in json:
        if pool_entity.get("name", None) is None or pool_entity.get("keysRootFolder", None) is None or pool_entity.get("ip", None) is None:
            raise ValueError