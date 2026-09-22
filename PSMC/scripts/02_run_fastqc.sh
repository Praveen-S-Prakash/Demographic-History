#!/bin/bash

# ============================================================
# FastQC analysis
# ============================================================
#
# Purpose:
#   Run FastQC on all compressed FASTQ files in the input
#   directory using GNU parallel.
#
# ============================================================

# Input directory
INPUT_DIR="/media/birdlab/HDD_16/raw_seq_data/NCGM_4524/"

# Output directory
OUTPUT_DIR="/media/birdlab/HDD_16/raw_seq_data/NCGM_4524/fastqc_output/"

# Number of parallel jobs
THREADS=10

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run FastQC in parallel
find "$INPUT_DIR" -type f -name "*.fastq.gz" | \
    parallel -j "$THREADS" "fastqc {} -o '$OUTPUT_DIR'"
