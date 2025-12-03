# maxit-ccd
A Dockerfile repository for [MAXIT](https://sw-tools.rcsb.org/apps/MAXIT/), which regularly updates wwPDB's resources, especially [PDBx/mmCIF Dictionary](https://mmcif.wwpdb.org/) and [Chemical Component Dictionary](https://www.wwpdb.org/data/ccd). The Docker image will be published on every Wednesday (03:10~ UTC).

## Usage
```shell
# First, pull the Docker image from the GitHub Container Repository
docker pull ghcr.io/yokochi47/maxit-ccd:main

# Then, run the image with memory limit (e.g. 16GB, no swap)
docker run -m 16g --memory-swap 16g ghcr.io/yokochi47/maxit-ccd:main -input inputfile -output outputfile -o num [ -log logfile ]

# Or, run 'maxit' alias command
alias maxit='docker -m 16g --memory-swap 16g run ghcr.io/yokochi47/maxit-ccd:main'

maxit -input inputfile -output outputfile -o num [ -log logfile ]
```
