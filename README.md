# Indy_Testbed_Setup

A series of scripts to ease the setup of an [Indy](https://www.hyperledger.org/projects/hyperledger-indy) pool, that can run either locally or over the Internet.

## Purpose

The purpose of the repo is to allow entities and/or organizations to setup a shared network of trustees, stewards and nodes (according to prior agreements) in a very intuitive manner.

The final result is a pool of validator nodes run in Docker containers, that produce content (e.g., logs and ledger data) available to the host machine through volumes mounting.

## Structure

On a general level, the main entities interacting with the repository to setup the pool are two: the **pool creator**, responsible to collect the initial required information from the other entities involved in the _genesis transactions_, and the **members**, i.e., the entities involved in the initial setup of the pool but that do not have the duty of generating the actual genesis transactions or collect information from the other partners. A better description of the process is explained in the next sections.

The repository is so divided:

- `common`: this folder contains scripts that are usually used by all the parties involved, such as those for generating the needed keys to interact with the pool and the ledger.
- `containers`: the content of this folder is not actively used. It contains files that allow to spin up the Docker containers running the validator node software (one per steward, i.e., one per partner entity involved).
- `creator`: all the scripts that the entity responsible to create the pool needs to execute in order to produce the needed configuration files to run the network.
- `member`: the entities that participate in the network setup, albeit not as creators, will interact with the scripts in this folder in order to join the initial network.
- `utils`: utility functions both for internal use as well as available to users to, e.g., download all the needed dependencies to execute the scripts and launch the containers.

## Network creation

The following subsections describe the whole process of setting up an Indy network.

**Due the nature of Hyperldeger Indy, unless for mere testing purposes where security is not required, the process cannot be automatized any further.** This means that there are some steps that require all the initial entities to produce some output that must be sent to the pool creator. The creator will then collect all the information received and will generate the domain and pool genesis transactions files. Such files are then sent back to all the partners involved.

### Key material generation

**The scripts in this sub-section rely on the [indy-plenum](https://github.com/hyperledger/indy-plenum) package. This module does not yet support Ubuntu 18.04, hence it requires an Ubuntu 16.04 machine with Python3 installed.**

This is the first step in the pool setup process. In this step, all the entities that want to join the initial network need to produce keys and send it to the network creator through some external channel. **Since only public information is exchanged, it is enough to ensure authentication and integrity of the data exchanged.** This process must be performed by all the parties willing to join the network, including the network creator, if so agreed.

1. Install dependencies: move to the `utils` folder and run `./setup_deps.sh`. This will take care of installing all the needed dependencies, e.g., `pip3` and `indy-node` executables.
2. Keys generation: move back to the `common` folder. Here, depending on the agreements among the different entities involved, keys for TRUSTEEs, STEWARDs and NODEs can be generated. So, for instance, if a partners wishes to join the network as TRUSTEE but also wishes to have its own validator node, he needs to generate keys for TRUSTEE, STEWARD (the only entity that can add a NODE), and NODE.

`./generate_keys.sh --name <TRUSTEE_ENTITY_NAME> --role TRUSTEE [--seed <SEED>] [--force]`
`./generate_keys.sh --name <STEWARD_ENTITY_NAME> --role STEWARD [--seed <SEED>] [--force]`
`./generate_keys.sh --name <NODE_ENTITY_NAME> --role NODE [--seed <SEED>] [--force]`

These lines will generate keys for a TRUSTEE, a STEWARD and a NODE entity. The keys are saved in the `/keys/<TRUSTEE_ENTITY_NAME>`, `/keys/<STEWARD_ENTITY_NAME>`, and `/keys/<NODE_ENTITY_NAME>` respectively.

**Either using a pre-defined seed (if randomly generated) or capturing the auto-generated one printed shown on stdout after key creation is strongly recommended. In this way, in case the keys are lost, they can be re-generated with the same script and the same input arguments, by specifying the same seed used at pool creation time for the specific entity.**

Once the process is completed, each folder will contain a `keys.out` file. These files contain no confidential information and need to be sent to the network creator. Each file contains information about public encryption and public verification keys for the specific entity. If the keys belong to a validator node, it will also contain the BLS and the proof-of-possession for the BLS keys (more details [here](https://en.wikipedia.org/wiki/Boneh%E2%80%93Lynn%E2%80%93Shacham)).

_Agreements about which partners should have TRUSTEE priviledges and which partners can have a STEWARD role, being able to add their own validator node to the network, is external to this process and must be agreed upon among the parties involved via other means._

## Network setup generation

This step must be perfomed only by the entity responsible to generate the needed genesis transactions files. This can be done once all the partners have sent their own `keys.out` files.

1. (OPTIONAL) If the network creator did not generate any keys and did not install the dependencies, these can be installed now in the same way described in point 1 of the key material generation process description (above). But since _this process relies exclusively on Pyhton3 system packages, it can be executed on any OS with a default Python3 installation._
2. Open `/creator/pool_config.yaml` for modifications (replacing the current templated content). **For each `keys.out` file received**:
    - if the key belongs to a TRUSTEE or STEWARD, then in the `domain` section add the following information:
        - `alias`: the name of the entity, as specified in the file
        - `did`: the public key of the entity, as specified in the file
        - `verkey`: the verification key of the entity, as specified in the file
        - `role`: either TRUSTEE or STEWARD
    - if the key belongs to a NODE, then in the `pool` section add the following information:
        - `alias`: the name of the entity, as specified in the file
        - `verkey`: the verification key of the entity, as specified in the file
        - `bls_key`: the BLS key, as specified in the file
        - `pop_bls_key`: the proof-of-possession of the BLS key, as specified in the file
        - `ip`: the public IP used by the node. This must be agreed with the partner that will be running that node.
        - `node_port`: the port used by the node when communicating with other validator nodes. _Recommended value is **9701**._
        - `client_port`: the port used by the node when communicating with clients. _Recommended value is **9702**._
        - `steward_did`: the public key of the STEWARD owner of this node. The information can be found in the `keys.out` file relative to the STEWARD. **It is not possible to add a node without adding its STEWARD owner to the pool as well.** Make sure that the STEWARD's `did` and the NODE's `steward_did` match.
3. Once all the entities have been added to the pool configuration file, run `./init-pool.sh`.

When the script completes, the same directory will now contain both `domain_transactions_genesis` and `pool_transactions_genesis` files. These are the only files that allow other nodes to join the pool. The `pool_transactions_genesis` file is also responsible to allow clients to connect to and query the ledger.

These two files need now to be sent back to the partners involved. Again, the file does not contain any confidential information, so it is enough to ensure integrity and authenticity when sending it out to partners.

## Join network

Once a partner has received the `domain_transactions_genesis` and `pool_transactions_genesis` files, it can start the process to join the network. This is done by building and starting a Docker container with the proper two ports exposed, one for node-to-node and one for node-to-client communication. **In order to do this, also [Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/) and [Docker-Compose](https://docs.docker.com/compose/install/) need to be installed on the host machine and must be executable by non-root users (see the [post-installations steps](https://docs.docker.com/install/linux/linux-postinstall/) for a step-by-step process).**

1. Open `/member/node_config.yaml` for modifications (replacing the current templated content):
    - `node` section contains info about the node itself that will be running in the Docker container.
        - `alias`: the name of the node. Mainly used as name for log and internal config files.
        - `node_port`: the port the node will be using to communicate with other nodes. **Must be the same port specified during the genesis transaction generation for this node.**
        - `client_port`: the port the node will be using to communicate with other nodes. **Must be the same port specified during the genesis transaction generation for this node.**
        - `network`: the name of the network that the node will join. **Must be the same for all the nodes in the same pool.**
    - `binding` section contains info about links between the host machine and the Docker container that will run the Indy software.
        - `log_out`: path on the host machine where the logs produced by the dockerized node will be saved. _If the path does not exist, it will be created with all the needed intermediary directories._
        - `log_out`: path on the host machine where the ledger data obtained by the dockerized node will be saved. _If the path does not exist, it will be created with all the needed intermediary directories._
        - `keys_in`: path on the host machine where the keys for the node are saved. **This must point to an existing folder**, whose content and structure matches the one produced by the key generation scripts. The folder should contain the sub-folders `<NODE_ENTITY_NAME>` AND `<NODE_ENTITY_NAME`_`C`_`>`. The presence of the `keys.out` file is irrelevant at this point.
        - `pool_genesis_in`:  path on the host machine where the pool genesis file is 
        stored. This must point to an existing and valid pool genesis file.
        - `domain_genesis_in`:  path on the host machine where the domain genesis file is stored. This must point to an existing file and valid domain genesis file.

The startup process creates and starts a Docker container with the two specified ports exposed to the host machine. **It is responsibility of the entity managing the node to make sure that the node is accessible from the Internet through the specified ports.**

## Interacting with the pool

Once the pool is up and running, one of the several available [SDKs](https://github.com/hyperledger/indy-sdk) can be used. All the SDK needs is the pool genesis file, which contains the information about the validator nodes addresses and ports.