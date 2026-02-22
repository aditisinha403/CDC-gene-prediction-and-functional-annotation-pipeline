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

## Datasets

| Sample ID | Contigs | Total bp | Max Contig | N50 | GC% |
|-----------|---------|----------|------------|-----|-----|
| Bea3b88bb9 | 198 | 2,062,953 | 85,529 | 18,152 | ~26% |
| Bfe6f82f31 | 197 | 2,075,775 | 85,529 | 17,066 | ~26% |

---

## Environment

| Component | Version |
|-----------|---------|
| OS | macOS 15 (ARM64) / Linux x86_64 via Docker |
| CPU | Apple Silicon (M-series) with Rosetta 2 |
| Bash | GNU bash 5.x |
| Docker | 28.3.0 |
| Docker Compose | v2.x (bundled with Docker Desktop) |
| Perl | 5.38 (inside Docker container) |
| Python | 3.x (inside eggNOG-mapper container) |
| DIAMOND | bundled with eggNOG-mapper 2.1.12 |

---

## Tools

### Gene Prediction (ab initio)

| Tool | Version | Method Type | Rationale |
|------|---------|-------------|-----------|
| **GeneMarkS-2** | 1.15_1.25_lic | Ab initio (self-training HMM) | Requires [license](https://exon.gatech.edu/GeneMark/license_download.cgi). Runs via Docker (`--platform linux/amd64`). |
| **Prodigal** | TBD | Ab initio gene prediction | Optimized for prokaryotic genomes; fast and accurate |

### Gene Prediction (homology-based)

| Tool | Version | Method Type | Rationale |
|------|---------|-------------|-----------|
| **DIAMOND + SwissProt** | TBD | Homology-based | TBD |

### Functional Annotation

| Tool | Version | Rationale |
|------|---------|-----------|
| **Prokka** | TBD | TBD |
| **eggNOG-mapper** | 2.1.12 (emapper-2.1.12) | Orthology-based functional annotation using eggNOG v5.0.2 database with DIAMOND search. Provides COG, KEGG, GO, and Pfam annotations. Docker image: `quay.io/biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0` |

### Other

| Tool | Version | Rationale |
|------|---------|-----------|
| **barrnap** | TBD | Rapid identification of 16S, 23S, and 5S rRNA operons |
| **BLASTn** | TBD | Species-level identification via 16S rRNA |

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

---

## Prerequisites

1. **Docker** (v20+) installed and running
2. **GeneMarkS-2 license key**:
   - Go to https://exon.gatech.edu/GeneMark/license_download.cgi
   - Select: **GeneMarkS-2 version 1.15_1.25_lic** / **LINUX 64**
   - Fill in academic info (name, institution, email) and submit
   - Download both the **software tarball** and the **license key**
   - Install the key:
     ```bash
     gunzip gm_key.gz
     cp gm_key ~/.gmhmmp2_key
     ```
3. **Build GeneMarkS-2 Docker image**:
   ```bash
   # Extract the tarball
   tar xzf gms2_linux_64.tar.gz

   # Copy the Dockerfile into the extracted directory
   cp scripts/GeneMarkS2/Dockerfile gms2_linux_64/

   # Build the image (runs on x86_64 via Rosetta on ARM Macs)
   docker build --platform linux/amd64 -t genemarks2:1.15 gms2_linux_64/
   ```
   > **Note**: GeneMarkS-2 is proprietary software. The tarball and binaries
   > must NOT be committed to git. Each team member must download their own
   > copy from the link above.

4. **eggNOG-mapper database** (~47 GB, stored in Docker volume):
   ```bash
   # Download eggNOG v5.0.2 database into Docker volume
   bash scripts/eggNOG-mapper/run_eggnog.sh download
   ```
   > **Note**: The database is ~47 GB and is stored in a Docker volume
   > (`eggnog_db`), not in the git repository.

---

## Quick Start

```bash
# Run GeneMarkS-2 on both samples
bash scripts/GeneMarkS2/gms2_commands.sh

# Run eggNOG-mapper annotation on both samples
bash scripts/eggNOG-mapper/run_eggnog.sh annotate
bash scripts/eggNOG-mapper/run_eggnog.sh stats
```

---

## Directory Structure

```
├── Data/GeneMarkS2/                Input FASTA assemblies (2 samples)
├── scripts/
│   ├── GeneMarkS2/
│   │   ├── Dockerfile              Image definition (needs binaries to build)
│   │   ├── docker-compose.yml      Container orchestration config
│   │   └── gms2_commands.sh        Main run script (both samples)
│   └── eggNOG-mapper/
│       ├── run_eggnog.sh           Run script (download/annotate/stats)
│       └── eggnog_commands.sh      Commands record for reproducibility
├── results/
│   ├── GeneMarkS2/
│   │   ├── {sample}_gms2.gff.gz   Gene predictions (GFF, compressed)
│   │   ├── {sample}_gms2.faa      Protein sequences
│   │   ├── {sample}_gms2.fnn.gz   Nucleotide sequences (compressed)
│   │   └── gms2_summary.tsv       Comparison table
│   └── eggNOG-mapper/
│       ├── {sample}_eggnog.emapper.annotations  Main annotation table (TSV)
│       ├── {sample}_eggnog.emapper.hits          DIAMOND alignment hits
│       └── {sample}_eggnog.emapper.seed_orthologs Ortholog mappings
└── logs/
    ├── GeneMarkS2/
    │   └── {sample}_gms2_log.txt   Run logs with timestamps
    └── eggNOG-mapper/
        └── {sample}_eggnog.log     Run log + resource usage (time/RSS)
```

## Output Naming Convention

```
{sample}_{method}.{gff,gbk,faa,fnn}.gz
```

Example: `Bea3b88bb9_gms2.gff.gz`

---

## References

- Lomsadze A, Gemayel K, Tang S, Borodovsky M. (2018) Modeling leaderless transcription and atypical genes results in more accurate gene prediction in prokaryotes. *Genome Research* 28(7):1079-1089. [PubMed](https://pubmed.ncbi.nlm.nih.gov/29773659/)
- Cantalapiedra CP, Hernandez-Plaza A, Letunic I, Bork P, Huerta-Cepas J. (2021) eggNOG-mapper v2: functional annotation, orthology assignments, and domain prediction at the metagenomic scale. *Molecular Biology and Evolution* 38(12):5825-5829. [DOI](https://doi.org/10.1093/molbev/msab293)
- Huerta-Cepas J, et al. (2019) eggNOG 5.0: a hierarchical, functionally and phylogenetically annotated orthology resource. *Nucleic Acids Research* 47(D1):D309-D314. [DOI](https://doi.org/10.1093/nar/gky1085)
- Buchfink B, Reuter K, Drost HG. (2021) Sensitive protein alignments at tree-of-life scale using DIAMOND. *Nature Methods* 18:366-368. [DOI](https://doi.org/10.1038/s41592-021-01101-x)

---

## Status

GeneMarkS-2 gene prediction completed for both samples.
eggNOG-mapper functional annotation completed for both samples.
Pipeline expansion in progress (Prodigal, DIAMOND, Prokka).

---

## Contributors

- Zahra
- Aditi
- Fanshi
