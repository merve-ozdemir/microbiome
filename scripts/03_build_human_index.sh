#!/bin/bash
#SBATCH --job-name=03_build_human_index
#SBATCH --account=public
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=6G
#SBATCH --time=48:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Building the Bowtie2 index of the human reference and storing it in the QIIME 2 cache.
# Used by notebooks/03_host_removal.ipynb

set -euo pipefail

CACHE="/cluster/scratch/$USER/africangut/qiime_cache"

# Temporary files (downloads, combined FASTA) in scratch, deleted when the job ends
export TMPDIR="/cluster/scratch/$USER/africangut/tmp/$SLURM_JOB_ID"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

# Internet access through the ETH proxy, and the course environment
set +eu
source ~/.bashrc
module load eth_proxy
conda activate rachis-moshpit-2026.7
set -eu

# Downloading both references (details in notebook),
# combining them and building the Bowtie2 index 
qiime quality-control construct-human-pangenome-index \
    --p-threads 16 \
    --o-index "$CACHE:human_pangenome_index"
