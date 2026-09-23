#!/bin/bash

# MSMC2 - Themeda triandra
#
# This script runs MSMC2 using the multihetsep files generated
# from 9 phased samples. The analysis uses the -s option and
# includes the specified haplotypes.

# Paths
THREADS=12

MSMC2=/home/birdlab/softs/msmc_2.0.0_linux64bit

INPUT=/media/birdlab/HDD_16/raw_seq_data/MSMC/TT/multihetsep/TT_9combined_*.1.multihetsep.txt

PREFIX=TT_msmc2_phased

# Run MSMC2
echo "Running MSMC2 TT with -s flag..."

$MSMC2 -t $THREADS -s \
    -I 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17 \
    -o ${PREFIX}_TT_out \
    $INPUT

echo "TT MSMC2 runs completed successfully."
