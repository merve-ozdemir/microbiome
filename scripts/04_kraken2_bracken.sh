#!/bin/bash
#SBATCH --job-name=04_kraken2_bracken
#SBATCH --account=public
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=8G
#SBATCH --time=24:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Used by notebooks/04_taxonomy_kraken2_bracken.ipynb (after scripts/04_get_kraken2_db.sh is run)

set -euo pipefail

BATCH="$1"
CACHE="/cluster/scratch/$USER/africangut/qiime_cache"
OUT_DIR="/cluster/scratch/$USER/africangut/04_kraken2_bracken/$BATCH"
mkdir -p "$OUT_DIR"
echo "Batch: $BATCH"

# Temporary files in scratch, deleted when the job ends
export TMPDIR="/cluster/scratch/$USER/africangut/tmp/$SLURM_JOB_ID"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

# Activate the course environment 
set +eu; source ~/.bashrc; conda activate rachis-moshpit-2026.7; set -eu

# 1) Kraken 2
qiime annotate classify-kraken2 \
    --i-seqs "$CACHE:hostfree_reads_$BATCH" \
    --i-db "$CACHE:kraken2_db" \
    --p-threads 16 \
    --p-confidence 0.1 \
    --o-reports "$OUT_DIR/kraken2_reports.qza" \
    --o-outputs "$CACHE:kraken2_outputs_$BATCH" \
    --use-cache "$CACHE" \
    --verbose

# 2) Bracken
for LEVEL in S G; do
    qiime annotate estimate-bracken \
        --i-kraken2-reports "$OUT_DIR/kraken2_reports.qza" \
        --i-db "$CACHE:bracken_db" \
        --p-read-len 100 \
        --p-threshold 10 \
        --p-level "$LEVEL" \
        --p-no-include-unclassified \
        --o-reports "$OUT_DIR/bracken_reports_$LEVEL.qza" \
        --o-taxonomy "$OUT_DIR/bracken_taxonomy_$LEVEL.qza" \
        --o-table "$OUT_DIR/bracken_table_$LEVEL.qza" \
        --use-cache "$CACHE"
done

# 3) Export the Kraken 2 reports for the notebook
qiime tools export \
    --input-path "$OUT_DIR/kraken2_reports.qza" \
    --output-path "$OUT_DIR/kraken2_reports"
