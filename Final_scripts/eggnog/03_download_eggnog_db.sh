#!/usr/bin/env bash
set -euo pipefail

# Downloads the eggNOG v5.0.2 database (~47 GB).
# Can run on login node or as Slurm job (see src/slurm/download_eggnog.sbatch).
# Usage: bash src/setup/03_download_eggnog_db.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/activate_env.sh"

DB_DIR="${EGGNOG_DATA_DIR}"
mkdir -p "${DB_DIR}"

# Check if already downloaded
if [[ -f "${DB_DIR}/eggnog_proteins.dmnd" ]]; then
    echo "eggNOG database already exists at ${DB_DIR}"
    ls -lh "${DB_DIR}/"
    exit 0
fi

# Patch broken URL in conda-installed download script
# eggnog-mapper v2.1.12 hardcodes eggnogdb.embl.de which is now 404.
# See: https://github.com/eggnogdb/eggnog-mapper/issues/575
DOWNLOAD_SCRIPT=$(which download_eggnog_data.py)
echo "Download script: ${DOWNLOAD_SCRIPT}"

if grep -q "eggnogdb.embl.de" "${DOWNLOAD_SCRIPT}"; then
    echo "Patching broken URL: eggnogdb.embl.de -> eggnog5.embl.de"
    sed -i 's|http://eggnogdb.embl.de/download/emapperdb|http://eggnog5.embl.de/download/emapperdb|g' \
        "${DOWNLOAD_SCRIPT}"
    echo "Patch applied."
else
    echo "URL already correct (no patch needed)."
fi

echo ""
echo "=== Downloading eggNOG v5.0.2 database ==="
echo "Destination: ${DB_DIR}"
echo "Expected size: ~47 GB"
echo "Estimated time: 1-4 hours"
echo "Start: $(date)"
echo ""

download_eggnog_data.py --data_dir "${DB_DIR}" -y

echo ""
echo "End: $(date)"
echo "=== Download complete ==="
ls -lh "${DB_DIR}/"
du -sh "${DB_DIR}/"
