# ---- builder stage: fetch & build MAXIT from RCSB source ----
FROM alpine:latest AS builder

# Install tools needed to build MAXIT
RUN apk add --no-cache \
      bash \
      build-base \
      bison \
      flex \
      make \
      wget \
      gzip \
      tar

# Set working directory
WORKDIR /build

# Fetch the "latest version" marker, download corresponding tarball, extract and build.
# The RCSB site provides 'maxit-latest-version.txt' with the version string (e.g. "11.400").
RUN set -eux; \
    # Get version (e.g. "11.400") from RCSB
    VERSION="$(wget -qO- https://sw-tools.rcsb.org/apps/MAXIT/maxit-latest-version.txt)"; \
    echo "MAXIT version: $VERSION"; \
    TARBALL="maxit-v${VERSION}-prod-src.tar.gz"; \
    URL="https://sw-tools.rcsb.org/apps/MAXIT/${TARBALL}"; \
    echo "Downloading ${URL} ..."; \
    wget -q "${URL}"; \
    tar -xzf "${TARBALL}"; \
    # The tarball extracts to a directory named like "maxit-v${VERSION}-prod-src" or "maxit-v${VERSION}"
    RCSBROOT="$(tar -tzf ${TARBALL} | head -1 | cut -f1 -d '/')"; \
    echo "Source dir: ${RCSBROOT}"; \
    cd "${RCSBROOT}"; \
    export RCSBROOT; \
    ASCII_DIR="data/ascii"; \
    # Update Dictionary Definition Language (DDL)
    MMCIF_URL="https://mmcif.wwpdb.org/dictionaries/ascii"; \
    DDL_TARBALL="mmcif_ddl.dic.gz"; \
    DDL_URL="${MMCIF_URL}/${DDL_TARBALL}"; \
    DDL_LOC="${ASCII_DIR}/mmcif_ddl.dic"; \
    echo "Downloading ${DDL_URL} ..."; \
    wget -q "${DDL_URL}" \
    && gzip -d "${DDL_TARBALL}" -c > "${DDL_LOC}" \
    && rm "${DDL_TARBALL}"; \
    # Update PDBx/mmCIF Dictionary
    DIC_TARBALL="mmcif_pdbx_v50.dic.gz"; \
    DIC_URL="${MMCIF_URL}/${DIC_TARBALL}"; \
    DIC_LOC="${ASCII_DIR}/mmcif_pdbx.dic"; \
    echo "Downloading ${DIC_URL} ..."; \
    wget -q "${DIC_URL}" \
    && gzip -d "${DIC_TARBALL}" -c > "${DIC_LOC}" \
    && rm "${DIC_TARBALL}"; \
    # Update Chemical Component Dictionary (CCD)
    FILES_URL="https://files.wwpdb.org/pub/pdb/data/monomers"; \
    COMPONENTS_TARBALL="components.cif.gz"; \
    COMPONENTS_URL="${FILES_URL}/${COMPONENTS_TARBALL}"; \
    COMPONENTS_LOC="${ASCII_DIR}/component.cif"; \
    echo "Downloading ${COMPONENTS_URL} ..."; \
    wget -q "${COMPONENTS_URL}" \
    && gzip -d "${COMPONENTS_TARBALL}" -c > "${COMPONENTS_LOC}" \
    && rm "${COMPONENTS_TARBALL}"; \
    # Update Protonation Variants Companion Dictionary
    VARIANTS_TARBALL="aa-variants-v1.cif.gz"; \
    VARIANTS_URL="${FILES_URL}/${VARIANTS_TARBALL}"; \
    VARIANTS_LOC="${ASCII_DIR}/variant.cif"; \
    echo "Downloading ${VARIANTS_URL} ..."; \
    wget -q "${VARIANTS_URL}" \
    && gzip -d "${VARIANTS_TARBALL}" -c > "${VARIANTS_LOC}" \
    && rm "${VARIANTS_TARBALL}"; \
    # Build MAXIT (README-source instructs to run `make` then `make binary`)
    make; \
    make binary; \
    # Prepare an /opt tree to copy to runtime image
    mkdir -p /opt/data; \
    # Remove unnecessary executable files in bin directory
    rm -f bin/generate_assembly_cif_file bin/process_entry; \
    # Remove data/ascii directory to reduce image size
    rm -rf data/ascii; \
    # Copy application with its resource in the /opt tree
    cp -a bin /opt/; \
    cp -a data/binary /opt/data/

# ---- runtime stage: minimal Alpine with compiled MAXIT installed ----
FROM alpine:latest

# RCSBROOT environment variable to point to the installation directory
ENV RCSBROOT=/opt/maxit

# Create installation directory
RUN mkdir -p ${RCSBROOT}

# Copy bin directory from builder
COPY --from=builder /opt/bin ${RCSBROOT}/bin

# Copy data/binary directory from builder
COPY --from=builder /opt/data/binary ${RCSBROOT}/data/binary

# Set working directory
WORKDIR /data

# Set entrypoint
ENTRYPOINT ["/opt/maxit/bin/maxit"]
