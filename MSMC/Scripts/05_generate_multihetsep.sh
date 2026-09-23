#!/bin/bash

# MSMC - Generate multihetsep files
#
# This script generates multihetsep input files for MSMC by combining
# the merged phased VCFs and individual sample masks for 9 Themeda
# triandra samples. Reference mappability masks are also applied.
#
# Each scaffold is processed independently and in parallel.


set -euo pipefail

THREADS=30

##################################
# PATHS
##################################

MULTIHETSEP="/media/birdlab/HDD_16/raw_seq_data/MSMC/msmc-tools/generate_multihetsep.py"

SCAFF_LIST="/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/chromosome_list.txt"

# Individual sample masks
MASK_BASE="/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/variant_calls"

# Whatshap merged VCFs
VCF_BASE="/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/whatshap_merged"

# Reference mappability masks
REF_MASK_DIR="/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/mappability_mask"

# Output
OUTDIR="/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/multihetsep"

LOGDIR="${OUTDIR}/logs"

PREFIX="TT_9combined"

mkdir -p "$OUTDIR" "$LOGDIR"

##################################
# CHECK TOOL
##################################

python "$MULTIHETSEP" --help > /dev/null

echo "Starting MULTIHETSEP generation..."
echo

##################################
# FUNCTION
##################################

run_scaffold() {

    SCAF=$1

    # Sample list is defined inside the function so that
    # GNU Parallel jobs can access it
    SAMPLES=(
	    "60707400256-AVL-TT-0626-01-NCGM-5023_L001_filtered_sorted"
	    "60707400257-AVL-TT-0626-04-NCGM-5023_L001_filtered_sorted"
	    "60707400258-AVL-TT-0626-06-NCGM-5023_L001_filtered_sorted"
	    "60707400259-AVL-TT-0626-08-NCGM-5023_L001_filtered_sorted"
	    "60707400260-AVL-TT-0626-10-NCGM-5023_L001_filtered_sorted"
	    "60707400250-AVL-TT-0626-02-NCGM-5022_L001_filtered_sorted"
	    "60707400251-AVL-TT-0626-03-NCGM-5022_L001_filtered_sorted"
	    "60707400252-AVL-TT-0626-05-NCGM-5022_L001_filtered_sorted"
	    "60707400254-AVL-TT-0626-09-NCGM-5022_L001_filtered_sorted"
    )

    OUTFILE="${OUTDIR}/${PREFIX}_${SCAF}.multihetsep.txt"
    LOGFILE="${LOGDIR}/${SCAF}.log"

    echo "Processing $SCAF"

    ##################################
    # SKIP COMPLETED SCAFFOLDS
    ##################################

    if [[ -s "$OUTFILE" ]]; then
        echo "Already done: $SCAF"
        return
    fi

    ##################################
    # REFERENCE MAPPABILITY MASK
    ##################################

    REF_MASK="${REF_MASK_DIR}/GCA_057662145.1_ThtriWBW_chr${SCAF}.mask.bed.gz"

    ##################################
    # FILE CHECK: REFERENCE MASK
    ##################################

    if [[ ! -f "$REF_MASK" ]]; then
        echo "Missing reference mask: $REF_MASK" >> "$LOGFILE"
        echo "Skipping $SCAF: missing reference mask"
        return
    fi

    ##################################
    # FILE CHECK: ALL SAMPLE MASKS
    # AND MERGED VCFs
    ##################################

    for SAMPLE in "${SAMPLES[@]}"; do

        MASK_FILE="${MASK_BASE}/${SAMPLE}/${SAMPLE}.mask.${SCAF}.bed.gz"

        VCF_FILE="${VCF_BASE}/${SAMPLE}/${SAMPLE}.${SCAF}_merged_final.vcf.gz"

        if [[ ! -f "$MASK_FILE" ]]; then
            echo "Missing mask: $MASK_FILE" >> "$LOGFILE"
            echo "Skipping $SCAF: missing sample mask"
            return
        fi

        if [[ ! -f "$VCF_FILE" ]]; then
            echo "Missing VCF: $VCF_FILE" >> "$LOGFILE"
            echo "Skipping $SCAF: missing merged VCF"
            return
        fi

    done

    ##################################
    # BUILD MULTIHETSEP COMMAND
    ##################################

    CMD=(python "$MULTIHETSEP" --chr "$SCAF")

    # Add reference mappability mask
    CMD+=(--mask "$REF_MASK")

    # Add masks for all 9 samples
    for SAMPLE in "${SAMPLES[@]}"; do
        CMD+=(
            --mask
            "${MASK_BASE}/${SAMPLE}/${SAMPLE}.mask.${SCAF}.bed.gz"
        )
    done

    # Add merged VCFs for all 9 samples
    for SAMPLE in "${SAMPLES[@]}"; do
        CMD+=(
            "${VCF_BASE}/${SAMPLE}/${SAMPLE}.${SCAF}_merged_final.vcf.gz"
        )
    done

    ##################################
    # RUN MULTIHETSEP
    ##################################

    "${CMD[@]}" > "$OUTFILE" 2>> "$LOGFILE"

    ##################################
    # REMOVE EMPTY OUTPUT
    ##################################

    if [[ ! -s "$OUTFILE" ]]; then
        echo "Empty output; removing $OUTFILE" >> "$LOGFILE"
        rm -f "$OUTFILE"
        return
    fi

    echo "Finished $SCAF"
}

##################################
# EXPORT VARIABLES FOR GNU PARALLEL
##################################

export -f run_scaffold

export MULTIHETSEP
export MASK_BASE
export VCF_BASE
export OUTDIR
export LOGDIR
export PREFIX
export REF_MASK_DIR

##################################
# PARALLEL RUN
##################################

parallel -j "$THREADS" --halt soon,fail=1 \
    run_scaffold :::: "$SCAFF_LIST"

echo
echo "MULTIHETSEP generation finished."
