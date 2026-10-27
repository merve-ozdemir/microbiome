#!/bin/bash
#SBATCH --job-name=02_cache_raw_reads
#SBATCH --account=public
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8G
#SBATCH --time=06:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Used by notebooks/02_read_qc.ipynb

set -euo pipefail

CACHE="/cluster/scratch/$USER/africangut/qiime_cache"

# Temporary files in scratch, deleted when the job ends
export TMPDIR="/cluster/scratch/$USER/africangut/tmp/$SLURM_JOB_ID"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

# Activating the course environment 
set +eu; source ~/.bashrc; conda activate rachis-moshpit-2026.7; set -eu

# Creating the (empty) cache folder, unless it exists already
if [[ ! -d "$CACHE" ]]; then
    qiime tools cache-create --cache "$CACHE"
fi

# Unpacking the raw reads into the cache under the key "raw_reads"
qiime tools cache-store \
    --cache "$CACHE" \
    --artifact-path data/raw/african_gut_microbiomes_seqs.qza \
    --key raw_reads
