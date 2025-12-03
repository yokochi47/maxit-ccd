# ---- builder stage: fetch & build MAXIT from RCSB source ----
FROM alpine:latest AS builder

# Install build/runtime tools needed to build MAXIT
RUN apk add --no-cache \
      bash \
      build-base \
      bison \
      flex \
      make \
      wget \
      gzip \
      tar

# Work dir
WORKDIR /build

# Fetch the "latest version" marker, download corresponding tarball, extract and build.
# The RCSB site provides 'maxit-latest-version.txt' with the version string (e.g. "11.400").
RUN set -eux; \
    # get version (e.g. "11.400") from RCSB
    VERSION="$(wget -qO- https://sw-tools.rcsb.org/apps/MAXIT/maxit-latest-version.txt)"; \
    echo "MAXIT version: $VERSION"; \
    TARBALL="maxit-v${VERSION}-prod-src.tar.gz"; \
    URL="https://sw-tools.rcsb.org/apps/MAXIT/${TARBALL}"; \
    echo "Downloading ${URL}"; \
    wget -q "${URL}"; \
    tar -xzf "${TARBALL}"; \
    # the tarball extracts to a directory named like "maxit-v${VERSION}-prod-src" or "maxit-v${VERSION}"
    RCSBROOT="$(tar -tzf ${TARBALL} | head -1 | cut -f1 -d '/')"; \
    echo "Source dir: ${RCSBROOT}"; \
    cd "${RCSBROOT}"; \
    export RCSBROOT; \
    ASCII_DIR="data/ascii"; \
    # update dectionary definition language (DDL)
    MMCIF_URL="https://mmcif.wwpdb.org/dictionaries/ascii"; \
    DDL_TARBALL="mmcif_ddl.dic.gz"; \
    DDL_URL="${MMCIF_URL}/${DDL_TARBALL}"; \
    DDL_LOC="${ASCII_DIR}/mmcif_ddl.dic"; \
    echo "Downloading ${DDL_URL} ..."; \
    wget -q "${DDL_URL}" \
    && gzip -d "${DDL_TARBALL}" -c > "${DDL_LOC}" \
    && rm "${DDL_TARBALL}"; \
    # update PDBx/mmCIF dictionary
    DIC_TARBALL="mmcif_pdbx_v50.dic.gz"; \
    DIC_URL="${MMCIF_URL}/${DIC_TARBALL}"; \
    DIC_LOC="${ASCII_DIR}/mmcif_pdbx.dic"; \
    echo "Downloading ${DIC_URL} ..."; \
    wget -q "${DIC_URL}" \
    && gzip -d "${DIC_TARBALL}" -c > "${DIC_LOC}" \
    && rm "${DIC_TARBALL}"; \
    # update chemical component dictionary (CCD)
    FILES_URL="https://files.wwpdb.org/pub/pdb/data/monomers"; \
    COMPONENTS_TARBALL="components.cif.gz"; \
    COMPONENTS_URL="${FILES_URL}/${COMPONENTS_TARBALL}"; \
    COMPONENTS_LOC="${ASCII_DIR}/component.cif"; \
    echo "Downloading ${COMPONENTS_URL} ..."; \
    wget -q "${COMPONENTS_URL}" \
    && gzip -d "${COMPONENTS_TARBALL}" -c > "${COMPONENTS_LOC}" \
    && rm "${COMPONENTS_TARBALL}"; \
    # update variants dictionary
    VARIANTS_TARBALL="aa-variants-v1.cif.gz"; \
    VARIANTS_URL="${FILES_URL}/${VARIANTS_TARBALL}"; \
    VARIANTS_LOC="${ASCII_DIR}/variant.cif"; \
    echo "Downloading ${VARIANTS_URL} ..."; \
    wget -q "${VARIANTS_URL}" \
    && gzip -d "${VARIANTS_TARBALL}" -c > "${VARIANTS_LOC}" \
    && rm "${VARIANTS_TARBALL}"; \
    # build MAXIT (README-source instructs to run `make` then `make binary`)
    make; \
    make binary; \
    # prepare an /out tree to copy to runtime image
    mkdir -p /out; \
    cp -a bin /out/; \
    cp -a data/binary /out/data-binary || true; \
    # include other needed data files (the 'data' directory may contain ascii -> binary data)
    cp -a data /out/ || true

# ---- runtime stage: minimal Alpine with compiled MAXIT installed ----
FROM alpine:latest

# Create installation directory and copy files from builder
ENV RCSBROOT=/opt/maxit
RUN mkdir -p ${RCSBROOT}
COPY --from=builder /out/bin ${RCSBROOT}/bin
COPY --from=builder /out/data ${RCSBROOT}/data
# Some builds placed binary data in /out/data-binary; ensure it ends up in data/binary
RUN if [ -d /out/data-binary ]; then mkdir -p ${RCSBROOT}/data/binary && cp -a /out/data-binary/* ${RCSBROOT}/data/binary/ || true; fi || true

# Add bin to PATH
ENV PATH="${RCSBROOT}/bin:${PATH}"

# Set working dir
WORKDIR /data

# Default entrypoint: show version/help when container run without args.
# NOTE: the actual executable name often contains the version (e.g. maxit-v11.400-O).
# We use a shell wrapper to run any `maxit*` binary in ${RCSBROOT}/bin with passed args.
COPY --chown=root:root <<'EOS' /usr/local/bin/maxit-wrapper
#!/bin/sh
# Find the maxit executable in RCSBROOT/bin (pick the first executable matching "maxit*")
RCSBROOT=${RCSBROOT:-/opt/maxit}
BIN=$(ls "${RCSBROOT}/bin"/maxit* 2>/dev/null | head -n1)
if [ -z "$BIN" ]; then
  echo "ERROR: maxit executable not found in ${RCSBROOT}/bin" >&2
  exit 1
fi
exec "$BIN" "$@"
EOS
RUN chmod +x /usr/local/bin/maxit-wrapper

ENTRYPOINT ["/usr/local/bin/maxit-wrapper"]
CMD ["-h"]

