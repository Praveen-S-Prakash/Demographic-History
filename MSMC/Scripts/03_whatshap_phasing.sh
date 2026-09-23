#!/bin/bash

# ============================================================
# MSMC - Whatshap Phasing
#
# Purpose:
# Phase biallelic SNPs for each Themeda triandra sample and
# scaffold using WhatsHap, using the corresponding BAM files.
# Phasing statistics are also generated and combined into a
# single CSV file for each sample.
#
# Input:
#   - Deduplicated BAM files
#   - Per-scaffold VCF files from the MSMC variant-calling step
#   - Themeda triandra reference genome
#
# Output:
#   - Biallelic unphased VCFs
#   - Phased VCFs
#   - WhatsHap statistics for each scaffold
#   - Combined statistics CSV for each sample
#
# Software:
#   - bcftools
#   - WhatsHap
#   - bgzip/tabix
#   - GNU parallel
# ============================================================

set -euo pipefail
shopt -s nullglob

# PATHS

BAMS=(
	/mnt/SERB_NAS_Biogeography/raw-genomics/NCGM-5022/alignment_files/*rmdup.bam
        /mnt/SERB_NAS_Biogeography/raw-genomics/NCGM-5023/alignment_files/*rmdup.bam
)

echo "Number of BAMs: ${#BAMS[@]}"

if [[ ${#BAMS[@]} -eq 0 ]]; then
    echo "ERROR: No BAM files found!"
    exit 1
fi

VARIANT_WORKDIR="/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/variant_calls"
WHATSHAP_WORKDIR="/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/whatshap"

REF="/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/ref/GCA_057662145.1_ThtriWBW_v1.0_genomic.fna"

BCFTOOLS="/home/birdlab/softs/bcftools-1.10.2/bcftools"
BGZIP="/home/birdlab/softs/htslib-1.20/bgzip"
TABIX="/home/birdlab/softs/htslib-1.20/tabix"
SAMTOOLS="/usr/local/bin/samtools"

# ACTIVATE WHATSHAP ENV

source /home/birdlab/miniconda3/etc/profile.d/conda.sh
conda activate whatshap || { echo "ERROR: could not activate whatshap env"; exit 1; }

# LOOP OVER BAM FILES
for BAM in "${BAMS[@]}"; do

BASE=$(basename "$BAM")

if [[ "$BASE" == *_rmdup.bam ]]; then
    SAMPLE="${BASE%_rmdup.bam}"
else
    echo "Cannot parse sample name from $BASE"
    exit 1
fi

    VARIANT_DIR="${VARIANT_WORKDIR}/${SAMPLE}"

    SAMPLE_ROOT="${WHATSHAP_WORKDIR}/${SAMPLE}"
    UNPHASED_DIR="${SAMPLE_ROOT}/unphased"
    PHASED_DIR="${SAMPLE_ROOT}/phased"
    STATS_DIR="${SAMPLE_ROOT}/stats"

    mkdir -p "$UNPHASED_DIR" "$PHASED_DIR" "$STATS_DIR"

    echo "=============================="
    echo "Processing SAMPLE: $SAMPLE"
    echo "=============================="

    # PARALLEL PHASING PER SCAFFOLD

    parallel -j 4 --joblog "${SAMPLE_ROOT}/parallel.log" '
        VCF={}
        BASEVCF=$(basename "$VCF" .vcf.gz)

        UNPHASED_VCF="'"$UNPHASED_DIR"'/${BASEVCF}_biallelic_unphased.vcf.gz"
        PHASED_VCF="'"$PHASED_DIR"'/${BASEVCF}_biallelic_phased.vcf"
        STAT_FILE="'"$STATS_DIR"'/${BASEVCF}.stats.out"

        echo "Processing $BASEVCF"

        # Create biallelic SNP-only VCF
        "'"$BCFTOOLS"'" view -m2 -M2 -v snps -O z "$VCF" > "$UNPHASED_VCF"
        "'"$BCFTOOLS"'" index -f --csi "$UNPHASED_VCF"

        # Phase (limit threads inside whatshap)
        whatshap phase \
            --reference "'"$REF"'" \
            -o "$PHASED_VCF" \
            "$UNPHASED_VCF" \
            "'"$BAM"'"

        # Stats
        whatshap stats "$PHASED_VCF" --tsv "$STAT_FILE"

        # Compress phased
        "'"$BGZIP"'" -f "$PHASED_VCF"
        "'"$TABIX"'" -C -p vcf "${PHASED_VCF}.gz"

    ' ::: "${VARIANT_DIR}/${SAMPLE}".*.vcf.gz


    # MERGE ALL STATS INTO ONE CSV

    cd "$STATS_DIR"

    OUT="${SAMPLE}_whatshap_all_stats.csv"
    FILES=(*.stats.out)

    if [[ ${#FILES[@]} -eq 0 ]]; then
        echo "WARNING: No stats files found for $SAMPLE"
    else
        echo "Combining ${#FILES[@]} stats files into $OUT"

        head -n 1 "${FILES[0]}" | sed 's/\t/,/g' > "$OUT"

        for f in "${FILES[@]}"; do
            tail -n +2 "$f" | sed 's/\t/,/g' >> "$OUT"
        done

        echo "Combined stats saved to: $STATS_DIR/$OUT"
    fi

    echo "Finished ${SAMPLE}"
    echo

done

echo "Phasing pipeline completed successfully."
