# Docker container for SCALE-MAMBA

A Docker container script (Dockerfile) for the [SCALE-MAMBA secure multi-party computation framework](https://github.com/KULeuven-COSIC/SCALE-MAMBA) by the KU Leuven.

The container encapsulates the framework and it's dependencies. Since the framework expects configuration files to reside in hardcoded paths, running it in Docker containers makes it much easier to hold several configuration at once (in different containers or simply by swapping out volumes) and/or participate in several computations at once.

## Building

Ensure that the SCALE-MAMBA submodule is initialized correctly and up-to-date.
Build the Docker container manually by issuing
```
docker build -t <container_image_name>[:<container_image_tag>] -f Dockerfile
```
or using `make`
```
make [container] [CONTAINER=<container_image_name>] [TAG=<container_image_tag>]
```
where `container_image_name` and `container_image_tag` are optional parameters to specify the name and tag of the created Docker container image. The makefile sets default values as `lumip/scale-mamba:latest`.

The container is based on the alpine linux image and the build process proceeds in three main steps, each happening in a separate container:

1. Compiling dependencies: MPIR-3.0.0 and OpenSSL 1.1.0h
2. Compiling SCALE-MAMBA framework (from the SCALE-MAMBA subdirectory)
3. Creating the final _production_ image containing only the compiled binaries (and not build clutter)

Finally, issuing `make doc` will create the PDF documentation of the (original) framework within the SCALE-MAMBA/Documentation directory.

## Container Usage

The framework code resides in the `/scale-mamba` directory within the container (which is also the container's working directory) and the following three volumes are defined:

- `/scale-mamba/Data`: the Data directory of the framework. Contains configuration and memory files.
- `/scale-mamba/Cert-Store`: the `Cert-Store` directory of the framework. Contains certificates of all parties (as well as the private key for the party executed in the container)
- `/scale-mamba/Programs`: the `Program` directory of the framework. Contains `.mpc` source code as well as the programs compiled from it.

After setting up all required files in these directories (e.g. by copying a known configuration or executing the interactive `Setup` program by running `docker run --rm <container_image_name>[:<container_image_tag>] <volumes> Setup.x`) you must compile your program by running

```docker run --rm <volumes> <container_image_name>[:<container_image_tag>] compile.py Programs/<program_name>```

and then you can run a player in the container by invoking

```docker run --rm <volumes> <container_image_name>[:<container_image_tag>] <publish_port> Player.x <player_id> Programs/<program_name>```

where `<volumes>` is the volume assignment for the container, e.g., `-v certs:/scale-mamba/Cert-Store -v programs:/scale-mamba/Programs -v data:/scale-mamba/Data`, `<program_name>` is the name of your program, residing in source file `Programs/<program_name>/<program_name>.mpc` and `<public_port>` is configures port forwarding/publishing from the container.

Note that `Player.x` by default uses port `5000+<player_id>` and expects other players to use a port corresponding to their player id.

For more information on running the framework (as well as run-time parameters for `Player.x` and `compily.py`) please refer to the SCALE-MAMBA documentation.

For more information on how to tweak Docker container execution refer to the Docker documentation.

## Testing

The test scripts of the original SCALE-MAMBA repository have been adapted (cf. next section) to work with the Docker container. The easiest way to run tests is to invoke

```make test```

to run all available tests or 

```make test TEST=<test_name>```

to run only a specific test case on all available test configurations. Configurations are stored in the subfolder `Auto-Test-Data`  and available test cases are located in the `Programs` subdirectory of the SCALE-MAMBA repository.

The `test` target sets up Docker volumes prefixed with `lumip-scale-mamba`, a Docker network `lumip-scale-mamba-testnet` and a container `lumip-scale-mamba-dummy` for copying data to and from the volumes. Each test case will additionally spawn one container `lumip-scale-mamba-<player_id>` for each player involved in the test. All these will be cleaned up once the call to `make test` completes or is interrupted. The prefix is to avoid conflicts with already existing containers and can be changed (see below).

In addition to the three volumes mentioned above, testing creates another volume mounted at `/scale-mamba/Auto-Test-Data` which holds the contents of the `Auto-Test-Data` folder of the SCALE-MAMBA repository.

The following optional argument to `make test` can tweak the above behavior:

- `DOCKERPRE`: The prefix for created Docker objects. Default: `lumip-scale-mamba`
- `CONTAINER` and `TAG`: Same as for building the container, these arguments allow to specify the container image used during the tests.

Under the hood, `make test` just invokes the shell script `run_docker_tests.sh` as

```./run_docker_tests.sh $(DOCKERPRE) $(CONTAINER):$(TAG) "$(VOLUMES)" $(TEST)```

where `VOLUMES` is a variable containing the volume configuration as explained above to be passed into Docker commands and is assembled by the Makefile using the specified prefix.

Please note that running all tests takes a very long time (more than one day) and requires large amounts of main memory (at least 32 GiB for some tests, probably more).

## Tweaks to SCALE-MAMBA repository

The SCALE-MAMBA submodule does not point to the official SCALE-MAMBA repository because of some changes made in the SCALE-MAMBA test scripts to work with the container. These are maintained in the `docker_master` branch of [this fork](https://github.com/lumip/SCALE-MAMBA) of the official repository.

Additionally, that branch is configured to compile the main library of the framework as a shared library instead of a statically linked library, reducing the size of compiled binaries and thus the final Docker image by several megabytes.

Apart from the above, no changes have been made to the original framework code. Reasonable efforts will be made to keep the submodule up-to-date with the official repository.

## Security Warning

The authors of the SCALE-MAMBA framework does not come with any actual guarantee for security and must be understood as a research project. The same holds for the containerized version in this repository.

Apart from any weaknesses that might exist in the framework code, no guarantee is given to optimal configuration of the MPIR and OpenSSL libraries compiled as dependencies. However, any hints on how to improve security due to better configuration of these are welcome, please leave an [issue on github.com](https://lumip/SCALE-MAMBA-docker/issues/new).