#!/bin/bash

# ============================================================
# EV - VCF filtering and PLINK conversion
# ============================================================

# Input and output directories
inpath=/media/birdlab/HDD_16/raw_seq_data/SMC++/EV
outpath=/media/birdlab/HDD_16/raw_seq_data/GONe/EV

mkdir -p "$outpath"


# ============================================================
# 1. Extract biallelic SNPs
# ============================================================

bcftools view \
    -m2 \
    -M2 \
    -v snps \
    "$inpath/EV_9_sample_raw_vcf.vcf.gz" \
    -Oz \
    -o "$outpath/EV_9_sample_biallele.vcf.gz" \
    --threads 30


# ============================================================
# 2. Remove indels
# ============================================================

vcftools \
    --gzvcf "$outpath/EV_9_sample_biallele.vcf.gz" \
    --remove-indels \
    --recode \
    --recode-INFO-all \
    --stdout | bgzip > "$outpath/EV_9_sample_biallele_noindel.vcf.gz"


# ============================================================
# 3. Filter variants
# ============================================================

vcftools \
    --gzvcf "$outpath/EV_9_sample_biallele_noindel.vcf.gz" \
    --minGQ 30 \
    --minDP 5 \
    --maxDP 40 \
    --maf 0.05 \
    --hwe 0.05 \
    --max-missing 0.9 \
    --recode \
    --recode-INFO-all \
    --out "$outpath/EV_9_sample_biallele_noindel_filtered"


# ============================================================
# 4. Compress and index filtered VCF
# ============================================================

bgzip -c \
    "$outpath/EV_9_sample_biallele_noindel_filtered.recode.vcf" \
    > "$outpath/EV_9_sample_biallele_noindel_filtered.vcf.gz"

tabix -p vcf \
    "$outpath/EV_9_sample_biallele_noindel_filtered.vcf.gz"


# ============================================================
# 5. Convert VCF to PLINK format
# ============================================================

plink \
    --vcf "$outpath/EV_9_sample_biallele_noindel_filtered.vcf.gz" \
    --allow-extra-chr \
    --chr CM101839.1,CM101840.1,CM101841.1,CM101842.1,CM101843.1,CM101844.1 \
    --recode \
    --out "$outpath/EV_9_sample_biallele_noindel_filtered"
