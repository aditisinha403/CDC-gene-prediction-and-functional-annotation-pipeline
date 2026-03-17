#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# eggNOG-mapper annotation pipeline for Task 2
# Usage:
#   bash scripts/task2/eggnog/run_eggnog.sh download   # Step 1: download DB
#   bash scripts/task2/eggnog/run_eggnog.sh annotate    # Step 2: run annotation
#   bash scripts/task2/eggnog/run_eggnog.sh stats       # Step 3: extract statistics
# ============================================================

IMAGE="quay.io/biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0"
VOLUME="eggnog_db"
WORKSPACE="$(cd "$(dirname "$0")/../../.." && pwd)"
RESULTS="${WORKSPACE}/results/task2"
LOGS="${WORKSPACE}/logs/task2"
DATA="${WORKSPACE}/Data/task2"
CPUS=4

SAMPLES=("Bea3b88bb9" "Bfe6f82f31")

mkdir -p "${RESULTS}" "${LOGS}"

# ---- Step 1: Download eggNOG database ----
# NOTE: eggnog-mapper v2.1.12 hardcodes a broken URL (eggnogdb.embl.de, now 404).
# The correct server is eggnog5.embl.de. We patch the download script at runtime.
# See: https://github.com/eggnogdb/eggnog-mapper/issues/575
CORRECT_BASE="http://eggnog5.embl.de/download/emapperdb-5.0.2"

download_db() {
    echo "=== Downloading eggNOG v5.0.2 database to Docker volume '${VOLUME}' ==="
    echo "=== Using patched URL: ${CORRECT_BASE} ==="
    echo "This will download ~40-50 GB. Estimated time: 30 min - several hours."
    echo ""

    docker run --rm \
        -v ${VOLUME}:/data/db \
        ${IMAGE} \
        bash -c "
            # Patch the broken URL in download_eggnog_data.py
            sed -i 's|http://eggnogdb.embl.de/download/emapperdb|http://eggnog5.embl.de/download/emapperdb|g' \
                /usr/local/bin/download_eggnog_data.py && \
            echo 'Patched download URL: eggnogdb.embl.de -> eggnog5.embl.de' && \
            download_eggnog_data.py --data_dir /data/db -y
        "

    echo ""
    echo "=== Database download complete ==="
    echo "Checking database files:"
    docker run --rm -v ${VOLUME}:/data/db ${IMAGE} ls -lh /data/db/
}

# ---- Step 2: Run eggNOG-mapper annotation ----
annotate() {
    echo "=== Running eggNOG-mapper annotation ==="

    for SAMPLE in "${SAMPLES[@]}"; do
        FAA="${RESULTS}/${SAMPLE}_gms2.faa"

        if [[ ! -f "${FAA}" ]]; then
            echo "ERROR: Protein file not found: ${FAA}"
            echo "Run GeneMarkS-2 or Prodigal first to generate .faa files."
            exit 1
        fi

        echo ""
        echo "--- Annotating ${SAMPLE} ---"
        echo "Input: ${FAA} ($(wc -l < "${FAA}") lines)"
        echo "Start time: $(date)"

        # Run eggNOG-mapper with DIAMOND mode
        /usr/bin/time -l docker run --rm \
            -v ${VOLUME}:/data/db \
            -v "${RESULTS}":/results \
            ${IMAGE} \
            emapper.py \
                -i /results/${SAMPLE}_gms2.faa \
                -o /results/${SAMPLE}_eggnog \
                --data_dir /data/db \
                -m diamond \
                --cpu ${CPUS} \
                --tax_scope Bacteria \
                --go_evidence non-electronic \
                --override \
            2>&1 | tee "${LOGS}/${SAMPLE}_eggnog.log"

        echo "End time: $(date)"
        echo "--- ${SAMPLE} done ---"
    done

    echo ""
    echo "=== All annotations complete ==="
    ls -lh "${RESULTS}"/*eggnog*
}

# ---- Step 3: Extract statistics ----
stats() {
    echo "=== eggNOG-mapper Annotation Statistics ==="
    echo ""

    for SAMPLE in "${SAMPLES[@]}"; do
        ANNOT="${RESULTS}/${SAMPLE}_eggnog.emapper.annotations"

        if [[ ! -f "${ANNOT}" ]]; then
            echo "WARNING: ${ANNOT} not found, skipping ${SAMPLE}"
            continue
        fi

        echo "--- ${SAMPLE} ---"

        # Total annotated proteins (skip comment lines)
        TOTAL=$(grep -cv '^#' "${ANNOT}" || echo 0)
        echo "  Annotated proteins: ${TOTAL}"

        # Proteins with COG category
        COG=$(grep -v '^#' "${ANNOT}" | awk -F'\t' '$7!="-" && $7!=""' | wc -l | tr -d ' ')
        echo "  With COG category:  ${COG}"

        # Proteins with KEGG KO
        KO=$(grep -v '^#' "${ANNOT}" | awk -F'\t' '$12!="-" && $12!=""' | wc -l | tr -d ' ')
        echo "  With KEGG KO:       ${KO}"

        # Proteins with GO terms
        GO=$(grep -v '^#' "${ANNOT}" | awk -F'\t' '$10!="-" && $10!=""' | wc -l | tr -d ' ')
        echo "  With GO terms:      ${GO}"

        # Proteins with Pfam
        PFAM=$(grep -v '^#' "${ANNOT}" | awk -F'\t' '$21!="-" && $21!=""' | wc -l | tr -d ' ')
        echo "  With PFAMs:         ${PFAM}"

        echo ""
        echo "  COG category distribution (Top 10):"
        grep -v '^#' "${ANNOT}" | awk -F'\t' '$7!="-" && $7!=""{print $7}' \
            | fold -w1 | sort | uniq -c | sort -rn | head -10 \
            | while read count cat; do
                echo "    ${cat}: ${count}"
            done
        echo ""
    done
}

# ---- Main ----
case "${1:-help}" in
    download)  download_db ;;
    annotate)  annotate ;;
    stats)     stats ;;
    help|*)
        echo "Usage: bash $0 {download|annotate|stats}"
        echo ""
        echo "  download  - Download eggNOG v5.0.2 database (~40-50 GB)"
        echo "  annotate  - Run eggNOG-mapper on both samples"
        echo "  stats     - Extract annotation statistics"
        ;;
esac
