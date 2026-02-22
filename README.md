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
| **eggNOG-mapper** | TBD | TBD |

### Other

| Tool | Version | Rationale |
|------|---------|-----------|
| **barrnap** | TBD | Rapid identification of 16S, 23S, and 5S rRNA operons |
| **BLASTn** | TBD | Species-level identification via 16S rRNA |

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

---

## Quick Start

```bash
# Run GeneMarkS-2 on both samples
bash scripts/GeneMarkS2/gms2_commands.sh
```

---

## Directory Structure

```
├── Data/GeneMarkS2/            Input FASTA assemblies (2 samples)
├── scripts/GeneMarkS2/
│   ├── Dockerfile              Image definition (needs binaries to build)
│   ├── docker-compose.yml      Container orchestration config
│   └── gms2_commands.sh        Main run script (both samples)
├── results/GeneMarkS2/
│   ├── {sample}_gms2.gff.gz    Gene predictions (GFF, compressed)
│   ├── {sample}_gms2.faa       Protein sequences
│   ├── {sample}_gms2.fnn.gz    Nucleotide sequences (compressed)
│   └── gms2_summary.tsv        Comparison table
└── logs/GeneMarkS2/
    └── {sample}_gms2_log.txt   Run logs with timestamps
```

## Output Naming Convention

```
{sample}_{method}.{gff,gbk,faa,fnn}.gz
```

Example: `Bea3b88bb9_gms2.gff.gz`

---

## References

- Lomsadze A, Gemayel K, Tang S, Borodovsky M. (2018) Modeling leaderless transcription and atypical genes results in more accurate gene prediction in prokaryotes. *Genome Research* 28(7):1079-1089. [PubMed](https://pubmed.ncbi.nlm.nih.gov/29773659/)

---

## Status

GeneMarkS-2 gene prediction completed for both samples.
Pipeline expansion in progress (Prodigal, DIAMOND, Prokka, eggNOG-mapper).

---

## Contributors

- Zahra
- Aditi
- Fanshi
