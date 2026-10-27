#!/bin/bash
#SBATCH --job-name=02_read_qc
#SBATCH --account=public
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=2G
#SBATCH --time=24:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Used by notebooks/02_read_qc.ipynb (after scripts/02_cache_raw_reads.sh is run)

set -euo pipefail

BATCH="$1"
CACHE="/cluster/scratch/$USER/africangut/qiime_cache"
OUT_DIR="/cluster/scratch/$USER/africangut/02_read_qc/$BATCH"
mkdir -p "$OUT_DIR"
echo "Batch: $BATCH"

# Temporary files in scratch, deleted when the job ends
export TMPDIR="/cluster/scratch/$USER/africangut/tmp/$SLURM_JOB_ID"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

# Activating the course environment 
set +eu; source ~/.bashrc; conda activate rachis-moshpit-2026.7; set -eu

# 1) Selecting this batch's samples from the raw reads in the cache
qiime demux filter-samples \
    --i-demux "$CACHE:raw_reads" \
    --m-metadata-file "results/02_batches/$BATCH.tsv" \
    --o-filtered-demux "$CACHE:raw_reads_$BATCH"

# 2) Quality control with fastp:
#    - adapters are trimmed (fastp default for paired reads)
#    - low-quality 3' ends are cut: a 4 bp window moves in from the end until its mean quality is >= 20
#    - read pairs in which a read is shorter than 75 bp afterwards are removed
#    The quality-controlled reads are saved in the cache; notebook 03 continues from there.
#    More details written in the notebooks!
qiime fastp process-seqs \
    --i-sequences "$CACHE:raw_reads_$BATCH" \
    --p-cut-tail \
    --p-cut-window-size 4 \
    --p-cut-mean-quality 20 \
    --p-length-required 75 \
    --p-thread 8 \
    --o-processed-sequences "$CACHE:qc_reads_$BATCH" \
    --o-reports "$OUT_DIR/fastp_reports.qza"

# 3) Exporting the per-sample fastp reports (one JSON file per sample) for the notebook
qiime tools export \
    --input-path "$OUT_DIR/fastp_reports.qza" \
    --output-path "$OUT_DIR/fastp_reports"

qiime tools cache-remove --cache "$CACHE" --key "raw_reads_$BATCH" # for space
