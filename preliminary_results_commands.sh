#!/bin/bash
# ==============================================================================
# Script: preliminary_results_commands.sh
# Purpose: End-to-end structural and functional annotation pipeline
# Tools: Barrnap, RNAmmer, Prodigal, GLIMMER, GeneMarkS-2, Interpro, eggnog
# ==============================================================================

# 1. Clean up old files to ensure a fresh start
rm -f *.log *.gff *.faa *.predict *.icm *_subset_clean.faa

# 2. Run the master loop for both assemblies
for genome in Bea3b88bb9_S01_L001_filtered.fasta Bfe6f82f31_S01_L001_filtered.fasta; do
    base=$(basename $genome .fasta)
    echo "------------------------------------------------"
    echo "STARTING ANALYSIS FOR: $base"
    echo "------------------------------------------------"
    
    # ---------------------------------------------------------
    # Phase 1: rRNA Prediction
    # ---------------------------------------------------------
    echo "[1/5] Running Barrnap..."
    (time barrnap $genome > ${base}_barrnap.gff) 2> ${base}_barrnap.log
    
    echo "[2/5] Running RNAmmer..."
    # -S bac specifies bacteria; -m lsu,ssu,tsu runs 23S, 16S, and 5S models
    (time rnammer -S bac -m lsu,ssu,tsu -gff ${base}_rnammer.gff < $genome) > ${base}_rnammer.log 2>&1
    
    # ---------------------------------------------------------
    # Phase 2: CDS Prediction & Translation
    # ---------------------------------------------------------
    echo "[3/5] Running Prodigal..."
    # -a generates the translated protein sequences needed for eggNOG/InterPro
    (time prodigal -i $genome -c -m -f gff -o ${base}_prodigal.gff -a ${base}_proteins.faa) > ${base}_prodigal.log 2>&1
    
    echo "[4/5] Running GLIMMER..."
    # Requires building the Interpolated Markov Model (.icm) first
    (time build-icm ${base}.icm < $genome && glimmer3 $genome ${base}.icm ${base}_glimmer) > ${base}_glimmer.log 2>&1
    
    echo "[5/5] Running GeneMarkS-2..."
    # Runs the self-training Hidden Markov Model algorithm
    (time ./gmes_linux_64_4/gmes_petap.pl --ES --sequence $genome) > ${base}_genemark.log 2>&1
    
    echo "Done with $base!"
done

# ---------------------------------------------------------
# Phase 3: Key Requirements & Post-Processing
# ---------------------------------------------------------
echo "================================================"
echo "Finalizing protein subsets for Web GUI submission for Interpro and Eggnog"

# Extract the first 10 proteins, remove stop codon asterisks (*), and clean headers
awk '/^>/{c++} c>10{exit} 1' Bea3b88bb9_S01_L001_filtered_proteins.faa | sed 's/\*//g' | cut -d' ' -f1 > Bea_subset_clean.faa
awk '/^>/{c++} c>10{exit} 1' Bfe6f82f31_S01_L001_filtered_proteins.faa | sed 's/\*//g' | cut -d' ' -f1 > Bfe_subset_clean.faa

echo "------------------------------------------------"
echo "PIPELINE COMPLETE"
echo "------------------------------------------------"
ls -lh data/ results/ logs/
