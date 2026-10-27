#!/bin/bash
#SBATCH --job-name=03_host_removal
#SBATCH --account=public
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=12G
#SBATCH --time=48:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Removes human (host) reads from one batch of quality-controlled reads with Bowtie2.
# Used by notebooks/03_host_removal.ipynb (after scripts/03_build_human_index.sh is run)

set -euo pipefail

BATCH="$1"
CACHE="/cluster/scratch/$USER/africangut/qiime_cache"
OUT_DIR="/cluster/scratch/$USER/africangut/03_host_removal/$BATCH"
mkdir -p "$OUT_DIR"
echo "Batch: $BATCH"

# Temporary files (Bowtie2 alignments) in scratch, deleted when the job ends
export TMPDIR="/cluster/scratch/$USER/africangut/tmp/$SLURM_JOB_ID"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

# Activating the course environment 
set +eu; source ~/.bashrc; conda activate rachis-moshpit-2026.7; set -eu

# 1) Align the read pairs to the human reference and keep only the pairs in which
#    neither read aligns (--p-exclude-seqs). More details in notbeook.
qiime quality-control filter-reads \
    --i-demultiplexed-sequences "$CACHE:qc_reads_$BATCH" \
    --i-database "$CACHE:human_pangenome_index" \
    --p-n-threads 8 \
    --p-mode local \
    --p-sensitivity sensitive \
    --p-exclude-seqs \
    --o-filtered-sequences "$CACHE:hostfree_reads_$BATCH" \
    --verbose

# 2) Count the read pairs left per sample
qiime demux summarize \
    --i-data "$CACHE:hostfree_reads_$BATCH" \
    --o-visualization "$OUT_DIR/hostfree_reads_summary.qzv"

qiime tools export \
    --input-path "$OUT_DIR/hostfree_reads_summary.qzv" \
    --output-path "$OUT_DIR/hostfree_reads_summary"
