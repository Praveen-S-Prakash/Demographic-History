#!/bin/bash

# ============================================================
# Variant calling for GONE analysis - EV
# ============================================================
#
# Purpose:
#   Generate a multisample VCF from BAM files for downstream
#   demographic analysis with GONE.
#
# Input:
#   Reference genome
#   BAM file list
#
# Output:
#   Compressed multisample VCF containing variant and invariant
#   sites, with depth and allele-depth information.
#
# ============================================================


# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

REF="/media/birdlab/HDD_16/raw_seq_data/NCGM_4449/ref_Elaeocarpus/ep_reference/GCA_046269325.1_CDU_Epet_genomic.fna"

BAMLIST="/media/birdlab/HDD_16/raw_seq_data/SMC++/EV/bamList_EV.txt"

OUTDIR="/media/birdlab/HDD_16/raw_seq_data/SMC++/EV/"


# ------------------------------------------------------------
# 2. Parameters
# ------------------------------------------------------------

THREADS=16


# ------------------------------------------------------------
# 3. Create output directory
# ------------------------------------------------------------

mkdir -p "$OUTDIR"


# ------------------------------------------------------------
# 4. Create reference sequence dictionary
# ------------------------------------------------------------

picard CreateSequenceDictionary \
    R="$REF" \
    O="${REF%.fna}.dict"


# ------------------------------------------------------------
# 5. Index BAM files
# ------------------------------------------------------------
#
# BAM indexing is currently disabled.
#
# while read BAM
# do
#     samtools index "$BAM"
# done < "$BAMLIST"


# ------------------------------------------------------------
# 6. Variant calling
# ------------------------------------------------------------
#
# bcftools mpileup + call
#
# The -A option retains sites that are not necessarily
# supported by an ALT allele, allowing variant + invariant
# sites to be represented in the output.
#
# ------------------------------------------------------------

bcftools mpileup \
    --threads "$THREADS" \
    -f "$REF" \
    -b "$BAMLIST" \
    -q 30 \
    -Q 20 \
    -C 50 \
    -a FORMAT/DP,FORMAT/AD \
    -Ou | \
bcftools call \
    --threads "$THREADS" \
    -m \
    -A \
    -Oz \
    -o "$OUTDIR/EV_9_sample_raw_vcf.vcf.gz"


# ------------------------------------------------------------
# 7. Index VCF
# ------------------------------------------------------------

tabix -p vcf \
    "$OUTDIR/EV_9_sample_raw_vcf.vcf.gz"


echo "Variant calling completed"
