# maxit-ccd
A Docker image repository for [MAXIT](https://sw-tools.rcsb.org/apps/MAXIT/), containing regularly updated wwPDB's resources, in particular [PDBx/mmCIF Dictionary](https://mmcif.wwpdb.org/) and [Chemical Component Dictionary (CCD)](https://www.wwpdb.org/data/ccd). The Docker container will be published on every Wednesday (03:10~ UTC) and deployed to the self-hosted servers.

## Usage

Pull the container
```shell
docker pull ghcr.io/yokochi47/maxit-ccd:main
```

Then, run maxit (defined as default command of the container) with memory limit (e.g. 16GB, no swap) that will prevent large amounts of memory being required when converting malformed PDB file
```shell
docker run -m 16g --memory-swap 16g ghcr.io/yokochi47/maxit-ccd:main -input inputfile -output outputfile -o num [ -log logfile ]
```

Or, run 'maxit' alias command
```shell
alias maxit='docker run -m 16g --memory-swap 16g ghcr.io/yokochi47/maxit-ccd:main'

maxit -input inputfile -output outputfile -o num [ -log logfile ]
```
