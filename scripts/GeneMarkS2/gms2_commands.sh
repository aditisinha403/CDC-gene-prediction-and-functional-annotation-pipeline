#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GeneMarkS-2 Gene Prediction Commands (docker-compose version)
# Tool: GeneMarkS-2 v1.15_1.25_lic (ab initio, self-training HMM)
# Date: 2026-02-19
#
# Prerequisites:
#   1. Docker + Docker Compose installed and running
#   2. GeneMarkS-2 downloaded from https://exon.gatech.edu/GeneMark/license_download.cgi
#      - Select: GeneMarkS-2 version 1.15_1.25_lic / LINUX 64
#   3. License key installed: cp gm_key ~/.gmhmmp2_key
#   4. Software tarball extracted to Download/gms2_linux_64/
#
# Run from project root:
#   cd /path/to/workspace
#   bash results/GeneMarkS2/gms2_commands.sh
#
# Useful docker-compose commands (run from scripts/GeneMarkS2/):
#   docker compose run --entrypoint bash gms2    # Enter container to explore
#   docker compose logs gms2                     # View logs of last run
#   docker compose down                          # Remove stopped containers
#   docker compose ps -a                         # List containers (including stopped)
#
# Output:
#   results/GeneMarkS2/{sample}_gms2.gff       Gene coordinates (GFF format)
#   results/GeneMarkS2/{sample}_gms2.faa       Protein sequences
#   results/GeneMarkS2/{sample}_gms2.fnn       Nucleotide sequences
#   results/GeneMarkS2/{sample}_gms2_log.txt   Run log with timing
#   results/GeneMarkS2/gms2_summary.tsv        Summary table (TSV)
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

COMPOSE_DIR="scripts/GeneMarkS2"
COMPOSE_FILE="${COMPOSE_DIR}/docker-compose.yml"

echo "Project root: $PROJECT_ROOT"

# ─────────────────────────────────────────────────
# Step 1: Build Docker image via docker-compose
# ─────────────────────────────────────────────────
echo ""
echo ">>> Step 1: Building Docker image via docker-compose..."
docker compose -f "$COMPOSE_FILE" build

# ─────────────────────────────────────────────────
# Step 2: Verify license key exists
# ─────────────────────────────────────────────────
echo ""
echo ">>> Step 2: Checking license key..."
if [[ ! -f "$HOME/.gmhmmp2_key" ]]; then
    echo "ERROR: License key not found at ~/.gmhmmp2_key"
    echo "  Fix: cp Download/gm_key ~/.gmhmmp2_key"
    exit 1
fi
echo "License key OK: ~/.gmhmmp2_key"

# ─────────────────────────────────────────────────
# Step 3: Create output directory
# ─────────────────────────────────────────────────
mkdir -p results/GeneMarkS2

# ─────────────────────────────────────────────────
# Step 4: Run GeneMarkS-2 on both samples
# ─────────────────────────────────────────────────
# docker-compose.yml defines:
#   - platform: linux/amd64 (Rosetta on ARM Mac)
#   - volumes: license key, input data, output dir
#   - SAMPLE env var controls which sample to process

SAMPLES=("Bea3b88bb9" "Bfe6f82f31")

for SAMPLE in "${SAMPLES[@]}"; do
    PREFIX="${SAMPLE}_gms2"
    LOG="results/GeneMarkS2/${PREFIX}_log.txt"

    echo ""
    echo ">>> Step 4: Running GeneMarkS-2 on ${SAMPLE}..."
    echo "    Input:  Data/GeneMarkS2/${SAMPLE}_S01_L001_filtered.fasta"
    echo "    Output: results/GeneMarkS2/${PREFIX}.gff"

    # Write run metadata to log
    {
        echo "=== GeneMarkS-2 Run Log ==="
        echo "Sample:    ${SAMPLE}"
        echo "Input:     Data/GeneMarkS2/${SAMPLE}_S01_L001_filtered.fasta"
        echo "Tool:      GeneMarkS-2 v1.15_1.25_lic"
        echo "Platform:  linux/amd64 (Docker Compose via Rosetta)"
        echo "Start:     $(date)"
        echo "---"
    } > "$LOG"

    START=$(date +%s)

    # docker compose run:
    #   --rm here only removes THIS run's container (not the service container)
    #   We use "run" with explicit command to override the sample
    SAMPLE="$SAMPLE" docker compose -f "$COMPOSE_FILE" run \
        --no-deps \
        --name "gms2_${SAMPLE}" \
        gms2 \
        --seq "/data/${SAMPLE}_S01_L001_filtered.fasta" \
        --genome-type bacteria \
        --output "/output/${PREFIX}.gff" \
        --format gff \
        --faa "/output/${PREFIX}.faa" \
        --fnn "/output/${PREFIX}.fnn" \
        2>&1 | tee -a "$LOG"

    END=$(date +%s)
    ELAPSED=$((END - START))

    CDS_COUNT=$(grep -c "CDS" "results/GeneMarkS2/${PREFIX}.gff" || echo 0)

    # Append timing to log
    {
        echo "---"
        echo "End:       $(date)"
        echo "Runtime:   ${ELAPSED}s"
        echo "CDS found: ${CDS_COUNT}"
    } >> "$LOG"

    echo "    Done in ${ELAPSED}s (${CDS_COUNT} CDS)"
done

# ─────────────────────────────────────────────────
# Step 5: Write summary to TSV + print to terminal
# ─────────────────────────────────────────────────
SUMMARY="results/GeneMarkS2/gms2_summary.tsv"

echo ""
echo ">>> Step 5: Writing results summary to ${SUMMARY}"
echo "─────────────────────────────────────────────────────────────────"
printf "%-15s %6s %10s %10s %8s %8s %8s\n" "Sample" "CDS" "Coding_bp" "Avg_len" "Native" "Atyp" "Partial"
echo "─────────────────────────────────────────────────────────────────"

{
    printf "sample\ttool\tcds_count\tcoding_bp\tavg_cds_len\tnative\tatypical\tpartial\n"
    for SAMPLE in "${SAMPLES[@]}"; do
        GFF="results/GeneMarkS2/${SAMPLE}_gms2.gff"
        awk -F'\t' -v sample="$SAMPLE" '
            /\tCDS\t/{
                split($9,a,"length ");
                split(a[2],b,";");
                len=b[1]+0; sum+=len; n++
                if ($9 ~ /gene_type native/) native++
                if ($9 ~ /gene_type atypical/) atypical++
                if ($9 ~ /partial/) partial++
            }
            END {
                # Terminal display
                printf "%-15s %6d %10d %10.1f %8d %8d %8d\n",
                    sample, n, sum, sum/n, native+0, atypical+0, partial+0 > "/dev/stderr"
                # TSV row
                printf "%s\tGeneMarkS-2\t%d\t%d\t%.1f\t%d\t%d\t%d\n",
                    sample, n, sum, sum/n, native+0, atypical+0, partial+0
            }
        ' "$GFF"
    done
} > "$SUMMARY" 2>&1

# Re-read TSV to print terminal table (cleaner than stderr trick)
echo "─────────────────────────────────────────────────────────────────"

# Actually let's just print cleanly
for SAMPLE in "${SAMPLES[@]}"; do
    GFF="results/GeneMarkS2/${SAMPLE}_gms2.gff"
    awk -F'\t' -v sample="$SAMPLE" '
        /\tCDS\t/{
            split($9,a,"length ");
            split(a[2],b,";");
            len=b[1]+0; sum+=len; n++
            if ($9 ~ /gene_type native/) native++
            if ($9 ~ /gene_type atypical/) atypical++
            if ($9 ~ /partial/) partial++
        }
        END {
            printf "%-15s %6d %10d %10.1f %8d %8d %8d\n",
                sample, n, sum, sum/n, native+0, atypical+0, partial+0
        }
    ' "$GFF"
done

# Write clean TSV
{
    printf "sample\ttool\tcds_count\tcoding_bp\tavg_cds_len\tnative\tatypical\tpartial\n"
    for SAMPLE in "${SAMPLES[@]}"; do
        GFF="results/GeneMarkS2/${SAMPLE}_gms2.gff"
        awk -F'\t' -v sample="$SAMPLE" '
            /\tCDS\t/{
                split($9,a,"length ");
                split(a[2],b,";");
                len=b[1]+0; sum+=len; n++
                if ($9 ~ /gene_type native/) native++
                if ($9 ~ /gene_type atypical/) atypical++
                if ($9 ~ /partial/) partial++
            }
            END {
                printf "%s\tGeneMarkS-2\t%d\t%d\t%.1f\t%d\t%d\t%d\n",
                    sample, n, sum, sum/n, native+0, atypical+0, partial+0
            }
        ' "$GFF"
    done
} > "$SUMMARY"

echo "─────────────────────────────────────────────────────────────────"
echo ""
echo "Summary written to: ${SUMMARY}"
echo ""
echo "Output files:"
ls -lh results/GeneMarkS2/*_gms2.{gff,faa,fnn} results/GeneMarkS2/gms2_summary.tsv 2>/dev/null

echo ""
echo "─────────────────────────────────────────────────────────────────"
echo "Containers are preserved. Useful commands:"
echo "  docker compose -f ${COMPOSE_FILE} ps -a          # List containers"
echo "  docker compose -f ${COMPOSE_FILE} logs           # View run logs"
echo "  docker exec -it gms2_Bea3b88bb9 bash             # Enter sample 1 container"
echo "  docker exec -it gms2_Bfe6f82f31 bash             # Enter sample 2 container"
echo "  docker compose -f ${COMPOSE_FILE} down           # Clean up when done"
echo "─────────────────────────────────────────────────────────────────"
