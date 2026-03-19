#!/bin/bash
# ==============================================================================
# Group 2: Master Structural Annotation Pipeline
# Tools: Barrnap, RNAmmer, Prodigal, GLIMMER
# Note: Functional annotation (eggNOG-mapper) is executed via a separate script.
# ==============================================================================

# 1. Setup Directories
mkdir -p final_results/results
mkdir -p final_results/logs
mkdir -p final_results/data

echo "Starting structural annotation pipeline for all genomes in data/..."

# 2. Execution Loop
for genome in data/*.fasta; do
    base=$(basename "$genome" .fasta)
    echo "Processing $base..."

    # ---------------------------------------------------------
    # PHASE 1: rRNA Detection (2 Methods)
    # ---------------------------------------------------------
    
    echo "  -> Running Barrnap..."
    barrnap "$genome" > "final_results/results/${base}_barrnap.gff" 2> "final_results/logs/${base}_barrnap.log"
    
    echo "  -> Running RNAmmer..."
    rnammer -S bac -m lsu,ssu,tsu -gff "final_results/results/${base}_rnammer.gff" < "$genome" > "final_results/logs/${base}_rnammer.log" 2>&1

    # ---------------------------------------------------------
    # PHASE 2: Gene Prediction / CDS (2 Methods)
    # ---------------------------------------------------------
    
    echo "  -> Running Prodigal..."
    prodigal -i "$genome" \
             -o "final_results/results/${base}_prodigal.gff" \
             -a "final_results/data/${base}_proteins.faa" \
             -f gff \
             > "final_results/logs/${base}_prodigal.log" 2>&1
             
    echo "  -> Running GLIMMER..."
    build-icm "final_results/results/${base}.icm" < "$genome" 2> /dev/null
    glimmer3 "$genome" "final_results/results/${base}.icm" "final_results/results/${base}_glimmer" > "final_results/logs/${base}_glimmer.log" 2>&1

    # Compress the Prodigal GFF to save space
    gzip -f "final_results/results/${base}_prodigal.gff"

done

echo "Structural pipeline execution complete! Check final_results/logs for details."
