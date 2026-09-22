#!/bin/bash

# ============================================================
# SHA256 checksum verification
# ============================================================
#
# Purpose:
#   Verify the integrity of FASTQ files using their associated
#   SHA256 checksum files.
#
# Input:
#   .fastq.gz files
#   .fastq.gz.sha256 checksum files
#
# Output:
#   Individual checksum files, per-file verification logs,
#   and a master verification summary.
#
# ============================================================

# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

# Folder containing the original FASTQ and checksum files
DATA_DIR="/mnt/SERB_NAS_Biogeography/raw-genomics/NCGM-5023"

# Destination directory for the processed data
OUT_DIR="/media/birdlab/HDD_16/raw_seq_data/NCGM_5023"

# Directory for checksum files and verification logs
CHECKSUM_DIR="$OUT_DIR/sha256sum"

# Master verification log
MASTER_LOG="$CHECKSUM_DIR/all_sha256_checks_summary.txt"


# ------------------------------------------------------------
# 2. Create output directory
# ------------------------------------------------------------

mkdir -p "$CHECKSUM_DIR"


# ------------------------------------------------------------
# 3. Initialise master log
# ------------------------------------------------------------

echo "SHA256SUM VERIFICATION SUMMARY" > "$MASTER_LOG"
echo "================================" >> "$MASTER_LOG"


# ------------------------------------------------------------
# 4. Verify each FASTQ file
# ------------------------------------------------------------

find "$DATA_DIR" -type f -name "*.fastq.gz.sha256" | while read -r sha_file; do

    # Extract the checksum filename
    sha_filename=$(basename "$sha_file")

    # Extract the target FASTQ filename from the checksum file
    original_filename=$(cut -d' ' -f2 "$sha_file" | sed 's/\*//')

    # Build the full path to the FASTQ file
    full_fastq_path="$DATA_DIR/${sha_filename%.fastq.gz.sha256}.fastq.gz"

    # Extract the SHA256 hash
    hash_value=$(cut -d' ' -f1 "$sha_file")

    # Create a new checksum file containing the full FASTQ path
    new_sha_file="$CHECKSUM_DIR/$sha_filename"
    echo "$hash_value  $full_fastq_path" > "$new_sha_file"

    # Per-file verification log
    out_log="$CHECKSUM_DIR/${sha_filename}.check.txt"

    # Write verification information to the individual log
    # and the master summary
    echo "Verifying: $full_fastq_path" > "$out_log"

    {
        echo "File: $sha_filename"
        echo "Verifying: $full_fastq_path"
        sha256sum -c "$new_sha_file"
        echo ""
    } | tee -a "$out_log" >> "$MASTER_LOG"

done
```

