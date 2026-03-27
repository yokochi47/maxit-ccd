# maxit-ccd
A Docker image repository for [MAXIT](https://sw-tools.rcsb.org/apps/MAXIT/), containing regularly updated wwPDB's resources, in particular [PDBx/mmCIF Dictionary](https://mmcif.wwpdb.org/) and [Chemical Component Dictionary (CCD)](https://www.wwpdb.org/data/ccd). The Docker container will be published on every Wednesday (03:10~ UTC) and deployed to the self-hosted servers.

## Usage

### Pull the container
```shell
docker pull ghcr.io/yokochi47/maxit-ccd:main
```

### Check software and resource version information
You can check installed software and resource version information as environment variables.
```shell
docker run ghcr.io/yokochi47/maxit-ccd:main env

MAXIT_VER=11.400     # MAXIT version
DDL_VER=2.3.3        # Dictionary Descrition Language (DDL) version
DIC_VER=5.412        # PDBx/mmCIF Dictionary version
CCD_REL=2026-03-21   # Chemical Component Dictionary (CCD) release date 
VAR_REL=2025-09-21   # Variants Companion Dictionary release date
...
```

### MAXIT command usage
As you know, here's how to use MAXIT:
```
docker run ghcr.io/yokochi47/maxit-ccd:main maxit

Usage: maxit -input inputfile -output outputfile -o num [ -log logfile ]
  [-o  1: Translate PDB format file to CIF format file]
  [-o  2: Translate CIF format file to PDB format file]
  [-o  8: Translate CIF format file to mmCIF format file]
```

### Run MAXIT command
Next, prepare an arbitrary directory named `tmp` on the host machine to save the input file(s) `input.cif`.
<pre>
.
└── tmp
    └── input.cif
</pre>

To mount a `tmp` directory under a predefined working directory `data` on a container machine, use the `docker run -v` option.
```shell
docker run -v ./tmp:/data/tmp ghcr.io/yokochi47/maxit-ccd:main maxit -input tmp/input.cif -output tmp/output.cif -o 8 -log tmp/maxit.log
```

Finally, the output files `output.cif` and `maxit.log` will be created in the `tmp` directory. Conguraturation! :tada:
<pre>
.
└── tmp
    ├── input.cif    
    ├── output.cif
    └── maxit.log
</pre>

### MAXIT's memory leak countermeasures
To ensure a safe conversion, it is recommended to set memory limit (e.g., 16GB, no swap). This will prevent excessive memory usage when converting malformed PDB files.
```shell
docker run -v ./tmp:/data/tmp -m 16g --memory-swap 16g ghcr.io/yokochi47/maxit-ccd:main maxit -input tmp/input.pdb -output tmp/output.cif -o 1 -log tmp/maxit.log
```
