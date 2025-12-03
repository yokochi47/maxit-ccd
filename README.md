# maxit-ccd
A Dockerfile repository for [MAXIT](https://sw-tools.rcsb.org/apps/MAXIT/), which regularly updates wwPDB's resources, especially [PDBx/mmCIF Dictionary](https://mmcif.wwpdb.org/) and [Chemical Componet Dictionary](https://www.wwpdb.org/data/ccd). The Docker image will be published on every Wednesday (03:10~ UTC).

## Usage
```shell
# First, pull the Docker image from the GitHub Container Repository
docker pull ghcr.io/yokochi47/maxit-ccd:main

# Then, run the image explicitly  
docker run ghcr.io/yokochi47/maxit-ccd:main -input inputfile -output outputfile -o num [ -log logfile ]

# Or, run 'maxit' alias command
alias maxit='docker run ghcr.io/yokochi47/maxit-ccd:main'

maxit -input inputfile -output outputfile -o num [ -log logfile ]
```
