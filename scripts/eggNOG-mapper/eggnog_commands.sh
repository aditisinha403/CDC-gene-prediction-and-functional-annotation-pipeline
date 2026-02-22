#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# eggNOG-mapper Annotation Commands Record
# Tool: eggNOG-mapper v2.1.12 (emapper-2.1.12) + DIAMOND blastp
# Database: eggNOG v5.0.2 (eggnog_proteins.dmnd)
# Docker Image: quay.io/biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0
# Date: 2026-02-22
#
# This file records the actual commands executed for reproducibility and
# report writing. It is NOT meant to be re-run directly — use run_eggnog.sh
# instead.
#
# Input:
#   results/task2/{SAMPLE}_gms2.faa  (GMS2 predicted protein sequences)
#
# Output (per sample):
#   results/task2/{SAMPLE}_eggnog.emapper.annotations  — Main annotation table (TSV)
#   results/task2/{SAMPLE}_eggnog.emapper.hits          — DIAMOND hits
#   results/task2/{SAMPLE}_eggnog.emapper.seed_orthologs — Ortholog mappings
#   logs/task2/{SAMPLE}_eggnog.log                      — Run log + resource usage
# =============================================================================

# ─────────────────────────────────────────────────
# Step 0: Database setup (done once, ~47 GB)
# ─────────────────────────────────────────────────
# Database was downloaded into Docker volume 'eggnog_db' using:
#
#   docker run --rm \
#       -v eggnog_db:/data/db \
#       quay.io/biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0 \
#       bash -c "
#           sed -i 's|http://eggnogdb.embl.de/download/emapperdb|http://eggnog5.embl.de/download/emapperdb|g' \
#               /usr/local/bin/download_eggnog_data.py && \
#           download_eggnog_data.py --data_dir /data/db -y
#       "
#
# NOTE: eggnog-mapper v2.1.12 hardcodes a broken URL (eggnogdb.embl.de, now 404).
#       The sed command patches it to the correct server (eggnog5.embl.de).
#       See: https://github.com/eggnogdb/eggnog-mapper/issues/575

# ─────────────────────────────────────────────────
# Step 1: Run eggNOG-mapper annotation
# ─────────────────────────────────────────────────
# Executed via: bash scripts/task2/eggnog/run_eggnog.sh annotate
# The following Docker commands were run for each sample:

SAMPLES=("Bea3b88bb9" "Bfe6f82f31")

for SAMPLE in "${SAMPLES[@]}"; do

    # Actual command executed:
    /usr/bin/time -l docker run --rm \
        -v eggnog_db:/data/db \
        -v "results/task2":/results \
        quay.io/biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0 \
        emapper.py \
            -i /results/${SAMPLE}_gms2.faa \
            -o /results/${SAMPLE}_eggnog \
            --data_dir /data/db \
            -m diamond \
            --cpu 4 \
            --tax_scope Bacteria \
            --go_evidence non-electronic \
            --override \
        2>&1 | tee "logs/task2/${SAMPLE}_eggnog.log"

    # DIAMOND internally ran (logged by emapper.py):
    #   diamond blastp \
    #       -d '/data/db/eggnog_proteins.dmnd' \
    #       -q '/results/${SAMPLE}_gms2.faa' \
    #       --threads 4 \
    #       -o '/results/${SAMPLE}_eggnog.emapper.hits' \
    #       --sensitive --iterate \
    #       -e 0.001 --top 3 \
    #       --outfmt 6 qseqid sseqid pident length mismatch gapopen \
    #                  qstart qend sstart send evalue bitscore qcovhsp scovhsp

done

# ─────────────────────────────────────────────────
# Step 2: Results summary
# ─────────────────────────────────────────────────
#
# Sample Bea3b88bb9:
#   Annotated proteins: 1891 / ~2170 (87.1%)
#   With COG category:  1770 (93.6%)
#   With KEGG KO:       1445 (76.4%)
#   With GO terms:       914 (48.3%)
#   With PFAMs:         1747 (92.4%)
#   Wall time:          2887s (~48 min)
#   Peak RSS:           25 MB (Docker host-side)
#   Peak footprint:     13.6 MB (process-level)
#
# Sample Bfe6f82f31:
#   Annotated proteins: 1895 / ~2180 (86.9%)
#   With COG category:  1774 (93.6%)
#   With KEGG KO:       1444 (76.2%)
#   With GO terms:       916 (48.3%)
#   With PFAMs:         1751 (92.4%)
#   Wall time:          2839s (~47 min)
#   Peak RSS:           25 MB (Docker host-side)
#   Peak footprint:     13.8 MB (process-level)
#
# COG Top 10 categories (both samples):
#   S (Function unknown), L (Replication/recombination/repair),
#   M (Cell wall/membrane), J (Translation), C (Energy production),
#   H (Coenzyme transport), E (Amino acid transport), P (Inorganic ion),
#   K (Transcription), U (Intracellular trafficking)

# ─────────────────────────────────────────────────
# Key parameters explained
# ─────────────────────────────────────────────────
# -m diamond          : Use DIAMOND for sequence search (fast alternative to HMMER)
# --tax_scope Bacteria: Restrict search to bacterial orthologous groups
# --go_evidence non-electronic: Only use experimentally-validated GO annotations
# --sensitive --iterate: DIAMOND's sensitive mode with iterative refinement
#                        (set automatically by emapper.py for thorough search)
# -e 0.001 --top 3    : E-value threshold and keep top 3 hits per query
# --override           : Overwrite existing output files
