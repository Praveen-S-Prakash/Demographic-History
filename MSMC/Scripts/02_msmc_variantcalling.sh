#!/bin/bash

# ============================================================
# MSMC - Variant Calling Preparation
#
# Purpose:
# Prepare per-sample variant calls from deduplicated BAM files
# for MSMC analysis of Themeda triandra (TT).
#
# The script:
#   1. Defines paths to the reference genome and required tools.
#   2. Loops through the deduplicated BAM files.
#   3. Creates a separate output directory for each sample.
#   4. Prepares the files required for downstream MSMC analysis.
#
# Input:
#   - Deduplicated BAM files
#   - Themeda triandra reference genome
#
# Output:
#   - Per-sample variant-call files in the MSMC variant_calls
#     directory.
#
# Software:
#   - samtools
#   - bcftools
#   - MSMC-tools (bamCaller.py)
# ============================================================

set -euo pipefail
shopt -s nullglob

##################################
# PATHS
##################################

BAMCALLER=/media/birdlab/HDD_16/raw_seq_data/MSMC/msmc-tools/bamCaller.py
REF=/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/ref/GCA_057662145.1_ThtriWBW_v1.0_genomic.fna
SAMTOOLS=/usr/local/bin/samtools
BCFTOOLS=/home/birdlab/softs/bcftools-1.10.2/bcftools

WORKDIR=/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/variant_calls
SCAFF_LIST=/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/chromosome_list.txt

##################################
# BAM FILES
##################################

BAMS=(
	/mnt/SERB_NAS_Biogeography/raw-genomics/NCGM-5022/alignment_files/*rmdup.bam
	/mnt/SERB_NAS_Biogeography/raw-genomics/NCGM-5023/alignment_files/*rmdup.bam
)

##################################
# LOOP OVER BAMs
##################################
for BAM in "${BAMS[@]}"; do

    BASE=$(basename "$BAM")

    if [[ "$BASE" == *_rmdup.bam ]]; then
        SAMPLE="${BASE%_rmdup.bam}"
    else
        echo "Cannot parse sample name from $BASE"
        exit 1
    fi

    OUTDIR="${WORKDIR}/${SAMPLE}"
    mkdir -p "${OUTDIR}"
    cd "${OUTDIR}"

    echo "==============================="
    echo "Processing ${SAMPLE}"
    echo "==============================="

    ##################################
    # Index BAM (CSI required for large pseudochromosomes)
    ##################################

    #echo "Indexing BAM..."
    #$SAMTOOLS index -c "$BAM"

    ##################################
    # Estimate mean depth on ONE scaffold
    ##################################

    echo "Estimating depth on CM173014.1..."

DEPTH=$($SAMTOOLS depth -r CM173014.1 "$BAM" | \
    awk '{sum += $3} END {if (NR>0) print sum/NR; else print 0}')

    if [[ "$DEPTH" == "0" ]]; then
        echo "Depth calculation failed for $SAMPLE"
        exit 1
    fi

    echo "Mean depth = ${DEPTH}"

    ##################################
    # Variant calling per scaffold (parallel)
    ##################################

    echo "Calling variants..."

    parallel -j 3 --joblog parallel.log '
    '"${BCFTOOLS}"' mpileup \
        --threads 8 \
        -B -q 20 -Q 20 -C 50 \
        -r {} \
        --fasta-ref '"${REF}"' \
        '"${BAM}"' | \
    '"${BCFTOOLS}"' call -c -V indels | \
    '"${BAMCALLER}"' '"${DEPTH}"' '"${SAMPLE}"'.mask.{}.bed.gz | \
    gzip -c > '"${SAMPLE}"'.{}.vcf.gz
    ' :::: "${SCAFF_LIST}"

    echo "Finished ${SAMPLE}"
    echo

done

echo "All samples completed."
