#!/bin/bash

set -e  # Exit if any command fails

# ============================================================
# Generate diploid consensus FASTQ for PSMC
# ============================================================
#
# Purpose:
#   Generate diploid consensus FASTQ sequences from
#   duplicate-removed BAM files for downstream PSMC analysis.
#
# Input:
#   Duplicate-removed BAM files (*_rmdup.bam)
#
# Output:
#   Diploid consensus FASTQ files (*.fq.gz)
#
# ============================================================


# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

# Reference genome
reffile="/media/birdlab/HDD_16/raw_seq_data/NCGM_5022/ref_TT/ref/GCA_057662145.1_ThtriWBW_v1.0_genomic.fna"

# Output directory
outdir="/media/birdlab/HDD_16/raw_seq_data/NCGM_5022/PSMC"

# Email address
email="praveenprakash@labs.iisertirupat.ac.in"


# ------------------------------------------------------------
# 2. Software paths
# ------------------------------------------------------------

samtools="/mnt/d/Vishwa/psmc/softs/samtools-1.18/bin/samtools"

bcftools="/home/birdlab/softs/bcftools-1.10.2/bcftools"

vcfutils="/usr/local/bin/vcfutils.pl"


# ------------------------------------------------------------
# 3. Setup
# ------------------------------------------------------------

mkdir -p "$outdir"


# ------------------------------------------------------------
# 4. Generate diploid consensus sequences
# ------------------------------------------------------------

for bam_in in /media/birdlab/HDD_16/raw_seq_data/NCGM_5022/alignment_files/*_rmdup.bam
do

    sample=$(basename "$bam_in" _rmdup.bam)

    echo "Processing $sample..."

    "$bcftools" mpileup \
        --threads 8 \
        -C50 \
        -f "$reffile" \
        "$bam_in" | \
    "$bcftools" call -c - | \
    "$vcfutils" vcf2fq \
        -d 10 \
        -D 100 | \
    gzip > "$outdir/${sample}_diploid.fq.gz"

    echo "$sample done!"

done

