# B2
# GenePred-Annot (GPA)
**Group B2 – Gene Prediction & Functional Annotation**  

---

## Overview

GenePred-Annot (GPA) is a reproducible annotation pipeline designed to perform structural gene prediction and ribosomal RNA identification on bacterial genome assemblies.

This workflow operates downstream of **Group 1 (Read Cleaning & Genome Assembly)** and transforms assembled genomes into biologically interpretable annotations.

---

## Input

| Input File | Source |
|------------|--------|
| Assembled bacterial genome (.fna) | Group 1 – Read Cleaning & Genome Assembly |

---

## Output

| Output Type | File Content |
|----------|------------|
| CDS Annotation | Coding sequence predictions in GFF format |
| CDS Log File | Combined stdout and stderr execution log |
| 16S rRNA Sequences | Extracted 16S gene sequences in FASTA format |
| Species Identification | Top 5 BLASTn alignments against curated 16S database |


---

## Tools

| Tool | Function | Method Type | Rationale |
|------|----------|-------------|-----------|
| **Prodigal** | Predict coding sequences (CDS) | Ab initio gene prediction | Optimized for prokaryotic genomes; fast and accurate |
| **barrnap** | Detect ribosomal RNA genes | rRNA feature detection | Rapid identification of 16S, 23S, and 5S rRNA operons |
| **BLASTn** | Species-level identification via 16S | Sequence homology alignment | Compares extracted 16S sequences against curated rRNA database |


---
---

## Theoretical Background

### Gene Prediction

Structural gene prediction in bacteria relies on ab initio methods that distinguish coding from non-coding regions using intrinsic sequence properties such as:

- Codon usage bias
- GC content differences
- Start and stop codon patterns
- Coding length distributions

Tools such as Prodigal implement probabilistic models similar to Hidden Markov Models (HMMs) to determine the most likely gene structure across a genome sequence.

---

### Functional Annotation

Following gene prediction, functional annotation assigns biological meaning to predicted coding sequences.

This process may include:

- Homology-based searches (e.g., BLAST)
- Domain identification
- Motif detection
- Taxonomic identification via conserved markers (e.g., 16S rRNA)

Species-level identification in this project is performed using 16S rRNA BLASTn searches against curated nucleotide databases.

---

### Interpretation Considerations

- High sequence identity and coverage are required for confident species assignment.
- Gene naming follows evidence-based logic:
  - High-confidence matches → direct functional transfer
  - Low-confidence matches → "putative"
  - No significant match → "hypothetical protein"
------
## Status

Project initialization phase.  
Pipeline structure and tool selection in progress.

---

## Contributors

- Zahra
- Aditi
- Franshi
