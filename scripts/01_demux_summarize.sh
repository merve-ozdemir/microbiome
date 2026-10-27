#!/bin/bash
#SBATCH --job-name=01_demux_summarize
#SBATCH --account=public
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=8G
#SBATCH --time=12:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Used by notebooks/01_data_import_and_inspection.ipynb

set -euo pipefail

READS="data/raw/african_gut_microbiomes_seqs.qza"
OUT_DIR="/cluster/scratch/$USER/africangut/01_raw_summary"   # large outputs stay in scratch
mkdir -p "$OUT_DIR" results

# QIIME 2 unpacks the ~150 GB artifact into a temporary folder.
# That folder is stored temporarily in my scratch. 
export TMPDIR="/cluster/scratch/$USER/africangut/tmp/$SLURM_JOB_ID"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

# Activating the course env 
set +eu; source ~/.bashrc; conda activate rachis-moshpit-2026.7; set -eu

# Counting the reads of every sample and building quality plots
# using a random subsample of 10,000 reads
qiime demux summarize \
    --i-data "$READS" \
    --o-visualization "$OUT_DIR/raw_reads_summary.qzv"

# Exporting the tables behind the visualization and copying the small ones into results/
qiime tools export \
    --input-path "$OUT_DIR/raw_reads_summary.qzv" \
    --output-path "$OUT_DIR/raw_reads_summary"
cp "$OUT_DIR/raw_reads_summary/per-sample-fastq-counts.tsv" results/01_raw_read_counts.tsv
cp "$OUT_DIR/raw_reads_summary/forward-seven-number-summaries.tsv" results/01_raw_quality_forward.tsv
cp "$OUT_DIR/raw_reads_summary/reverse-seven-number-summaries.tsv" results/01_raw_quality_reverse.tsv
