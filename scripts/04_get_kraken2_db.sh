#!/bin/bash
#SBATCH --job-name=04_get_kraken2_db
#SBATCH --account=public
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4G
#SBATCH --time=12:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Download the pre-built Kraken 2 / Bracken database "PlusPF" (build of 15 October 2025) 
# This is not the most recent version but I have to use this due to Euler's memory limit
# Gets stored in the QIIME 2 cache under two keys:
#   kraken2_db  (the Kraken 2 database: hash.k2d, opts.k2d, taxo.k2d)
#   bracken_db  (the Bracken files: database<read length>mers.kmer_distrib)
# Used by notebooks/04_taxonomy_kraken2_bracken.ipynb

set -euo pipefail

DB_NAME="k2_pluspf_20251015"
DB_URL="https://genome-idx.s3.amazonaws.com/kraken/$DB_NAME.tar.gz"
MD5_URL="https://genome-idx.s3.amazonaws.com/kraken/pluspf_20251015/pluspf.md5"
CACHE="/cluster/scratch/$USER/africangut/qiime_cache"
DB_DIR="/cluster/scratch/$USER/africangut/04_kraken2_db"
mkdir -p "$DB_DIR"
cd "$DB_DIR"

# Temporary files in scratch, deleted when the job ends
export TMPDIR="/cluster/scratch/$USER/africangut/tmp/$SLURM_JOB_ID"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

# Internet access through the ETH proxy, and the course env
set +eu
source ~/.bashrc
module load eth_proxy
conda activate rachis-moshpit-2026.7
set -eu

# 1) Downloads the database archive (83 GB) 
curl -fsSL -o "$DB_NAME.tar.gz" "$DB_URL"
curl -fsSL -o pluspf.md5 "$MD5_URL"

# 2) Checks the download (its checksum must match the published one)
grep "$DB_NAME.tar.gz" pluspf.md5 | md5sum -c -

# 3) Unpacks and sorts the files into the two folders for QIIME 2 
mkdir -p extracted kraken2 bracken
tar -xzf "$DB_NAME.tar.gz" -C extracted
mv extracted/*.k2d kraken2/
mv extracted/database*mers.kmer_distrib bracken/

# 4) Imports both parts into the QIIME 2 cache
qiime tools cache-import --cache "$CACHE" --key kraken2_db --type Kraken2DB --input-path kraken2
qiime tools cache-import --cache "$CACHE" --key bracken_db --type BrackenDB --input-path bracken

# 5) Keeps the small files, deletes the large copies
mkdir -p info
mv extracted/inspect.txt extracted/library_report.tsv pluspf.md5 info/
rm -rf "$DB_NAME.tar.gz" extracted kraken2 bracken
echo "Database $DB_NAME stored in the cache; description files in $DB_DIR/info"
