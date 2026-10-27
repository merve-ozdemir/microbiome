#!/bin/bash
#SBATCH --job-name=04_merge_results
#SBATCH --account=public
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16G
#SBATCH --time=02:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Used by notebooks/04_taxonomy_kraken2_bracken.ipynb

set -euo pipefail

BATCHES="CMR_126 GNB_101 GNB_151 MDG_101 TZA_151"
IN_DIR="/cluster/scratch/$USER/africangut/04_kraken2_bracken"
OUT_DIR="results/04_taxonomy"
mkdir -p "$OUT_DIR"

# Temporary files in scratch, deleted when the job ends
export TMPDIR="/cluster/scratch/$USER/africangut/tmp/$SLURM_JOB_ID"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

# Activate the course environment
set +eu; source ~/.bashrc; conda activate rachis-moshpit-2026.7; set -eu

for LEVEL in S G; do
    # Lists of the per-batch files, e.g. ".../CMR_126/bracken_table_S.qza .../GNB_101/bracken_table_S.qza ..."
    TABLES=""; TAXONOMIES=""
    for BATCH in $BATCHES; do
        TABLES="$TABLES $IN_DIR/$BATCH/bracken_table_$LEVEL.qza"
        TAXONOMIES="$TAXONOMIES $IN_DIR/$BATCH/bracken_taxonomy_$LEVEL.qza"
    done

    # Feature tables
    qiime feature-table merge \
        --i-tables $TABLES \
        --p-overlap-method error_on_overlapping_sample \
        --o-merged-table "$OUT_DIR/bracken_table_$LEVEL.qza"

    # Taxonomies: one taxonomy covering the taxa of all batches
    qiime feature-table merge-taxa \
        --i-data $TAXONOMIES \
        --o-merged-data "$OUT_DIR/bracken_taxonomy_$LEVEL.qza"
done

# Kraken 2 reports of all samples in one 
REPORTS=""
for BATCH in $BATCHES; do
    REPORTS="$REPORTS $IN_DIR/$BATCH/kraken2_reports.qza"
done
qiime annotate collate-kraken2-reports \
    --i-reports $REPORTS \
    --o-collated-reports "$OUT_DIR/kraken2_reports.qza"
