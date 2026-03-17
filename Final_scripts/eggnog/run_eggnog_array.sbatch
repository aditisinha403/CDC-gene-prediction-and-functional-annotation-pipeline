#!/usr/bin/env bash
#SBATCH -J eggnog_array
#SBATCH -A bios
#SBATCH --qos=coc-ice
#SBATCH -N 1
#SBATCH --ntasks-per-node=8
#SBATCH --mem=12G
#SBATCH -t 04:00:00
#SBATCH --array=0-28
#SBATCH -o /home/hice1/fmeng48/scratch/BIOL7210/sentinel_Group2/logs/eggnog_%A_%a.log

set -euo pipefail

cd /storage/ice1/9/0/fmeng48/BIOL7210/sentinel_Group2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source src/setup/activate_env.sh
source src/lib/utils.sh

THREADS=${SLURM_NTASKS:-8}

# Read sample ID for this array task
SAMPLE_LIST="src/slurm/eggnog_remaining_samples.txt"
SAMPLE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "${SAMPLE_LIST}")

if [[ -z "${SAMPLE}" ]]; then
    log_error "No sample found for array task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

log_info "Array task ${SLURM_ARRAY_TASK_ID}: processing sample ${SAMPLE}"

# Idempotency check
if is_done "${OUTPUT_DIR}/.done" "${SAMPLE}" "eggnog"; then
    log_info "Skipping ${SAMPLE} (already done)"
    exit 0
fi

setup_output_dirs "${OUTPUT_DIR}"

GMS2_DIR="${OUTPUT_DIR}/predictions/gms2"
EGGNOG_DIR="${OUTPUT_DIR}/annotations/eggnog"
LOG_DIR="${OUTPUT_DIR}/logs"

INPUT_FAA="${GMS2_DIR}/${SAMPLE}_gms2.faa"
if [[ ! -f "${INPUT_FAA}" ]]; then
    log_error "${SAMPLE}: GMS2 protein file not found: ${INPUT_FAA}"
    exit 1
fi

log_info "Running eggNOG-mapper on ${SAMPLE}..."

# Use local /tmp for temp files to avoid Lustre I/O bottleneck
EGGNOG_TEMP="/tmp/eggnog_${USER}_${SAMPLE}"
mkdir -p "${EGGNOG_TEMP}"

/usr/bin/time -v emapper.py \
    -i "${INPUT_FAA}" \
    -o "${EGGNOG_DIR}/${SAMPLE}_eggnog" \
    --data_dir "${EGGNOG_DATA_DIR}" \
    -m diamond \
    --cpu "${THREADS}" \
    --tax_scope Bacteria \
    --go_evidence non-electronic \
    --override \
    --temp_dir "${EGGNOG_TEMP}" \
    --scratch_dir "${EGGNOG_TEMP}" \
    > "${LOG_DIR}/${SAMPLE}_eggnog.log" 2> "${LOG_DIR}/${SAMPLE}_eggnog.metrics"

rm -rf "${EGGNOG_TEMP}"

ANNOTATIONS_FILE="${EGGNOG_DIR}/${SAMPLE}_eggnog.emapper.annotations"
if [[ ! -f "${ANNOTATIONS_FILE}" ]]; then
    log_error "${SAMPLE}: eggNOG annotations file not found: ${ANNOTATIONS_FILE}"
    exit 1
fi

ANNOTATED_COUNT=$(grep -cv '^#' "${ANNOTATIONS_FILE}" || echo 0)
log_info "${SAMPLE}: eggNOG annotated ${ANNOTATED_COUNT} proteins"

mark_done "${OUTPUT_DIR}/.done" "${SAMPLE}" "eggnog"
log_info "Array task ${SLURM_ARRAY_TASK_ID}: ${SAMPLE} complete"
