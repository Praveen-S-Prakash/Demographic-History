#!/bin/bash

set -euo pipefail

# ============================================================
# STEP 0: Generate mappability mask for the reference genome
# ============================================================

# ---------- USER SETTINGS ----------

REF="/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/ref/GCA_057662145.1_ThtriWBW_v1.0_genomic.fna"

SEQBILITY="/home/birdlab/softs/seqbility"

MSMC_TOOLS="/media/birdlab/HDD_16/raw_seq_data/MSMC/msmc-tools"

REF_NAME="GCA_057662145.1_ThtriWBW"

# Length of the k-mer used for mappability
KMER=35

# Number of sequences per split file
SPLIT_LINES=20000000

# Fraction used by gen_mask
RATIO=0.5

# Output directory
OUTDIR="mappability_mask"

# ---------- CREATE OUTPUT DIRECTORY ----------

mkdir -p "${OUTDIR}"

cd "${OUTDIR}"

echo "Reference: ${REF}"
echo "k-mer length: ${KMER}"
echo "Output directory: ${OUTDIR}"

# ============================================================
# 1. Create BWA index
# ============================================================

echo "Creating BWA index..."

bwa index "${REF}"

# ============================================================
# 2. Generate all K-mers from the reference
# ============================================================

echo "Generating ${KMER}-bp mers..."

"${SEQBILITY}/splitfa" "${REF}" "${KMER}" \
    | split -l "${SPLIT_LINES}" - x

# ============================================================
# 3. Map each K-mer back to the reference
# ============================================================

echo "Mapping K-mers back to reference..."

for SPLIT in x*; do

    echo "Processing ${SPLIT}..."

    bwa aln \
        -R 1000000 \
        -O 3 \
        -E 3 \
        "${REF}" \
        "${SPLIT}" \
        | bwa samse \
            "${REF}" \
            - \
            "${SPLIT}" \
            > "${SPLIT}.sam"

    gzip "${SPLIT}.sam"

done

# ============================================================
# 4. Generate raw mappability mask
# ============================================================

echo "Generating raw mappability mask..."

gzip -dc x*.sam.gz \
    | "${SEQBILITY}/gen_raw_mask.pl" \
    > reference_rawMask_${KMER}.fa

# ============================================================
# 5. Generate final mappability mask
# ============================================================

echo "Generating final mappability mask..."

"${SEQBILITY}/gen_mask" \
    -l "${KMER}" \
    -r "${RATIO}" \
    reference_rawMask_${KMER}.fa \
    > reference_mask_${KMER}_50.fa

# ============================================================
# 6. Generate MSMC2 BED files
# ============================================================

echo "Generating MSMC2 BED files..."

python3 "${MSMC_TOOLS}/makeMappabilityMask_py3.py" \
    "reference_mask_${KMER}_50.fa" \
     "${REF_NAME}"

echo "================================================"
echo "Mappability-mask generation completed."
echo "================================================"

