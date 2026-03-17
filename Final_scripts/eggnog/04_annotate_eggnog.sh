#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../setup/activate_env.sh"
source "${SCRIPT_DIR}/../lib/utils.sh"

THREADS="${THREADS:-4}"

log_info "Starting module 04_annotate_eggnog"
setup_output_dirs "${OUTPUT_DIR}"

GMS2_DIR="${OUTPUT_DIR}/predictions/gms2"
EGGNOG_DIR="${OUTPUT_DIR}/annotations/eggnog"
LOG_DIR="${OUTPUT_DIR}/logs"

for SAMPLE in $(discover_samples "${INPUT_DIR}"); do
    if is_done "${OUTPUT_DIR}/.done" "${SAMPLE}" "eggnog"; then
        log_info "Skipping ${SAMPLE} (already done)"
        continue
    fi

    INPUT_FAA="${GMS2_DIR}/${SAMPLE}_gms2.faa"
    if [[ ! -f "${INPUT_FAA}" ]]; then
        log_error "${SAMPLE}: GMS2 protein file not found: ${INPUT_FAA}"
        log_error "Run module 01_predict_gms2.sh first"
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
done

log_info "Module 04_annotate_eggnog complete"
