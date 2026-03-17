#!/bin/bash
#SBATCH -J eggnog_db_dl
#SBATCH -A bios
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=8G
#SBATCH -t 06:00:00
#SBATCH --qos=coc-ice
#SBATCH -o logs/eggnog_db_download_%j.log

# Downloads the eggNOG v5.0.2 database (~47 GB) on a compute node.
# Submit from project root: sbatch src/slurm/download_eggnog.sbatch

set -euo pipefail
cd "$HOME/scratch/BIOL7210/sentinel_GroupProject"
bash src/setup/03_download_eggnog_db.sh
