#!/bin/bash

# ============================================================
# EV - GONE2 bootstrap analysis
# ============================================================

# Input files and directories
pedfile=/media/birdlab/HDD_16/raw_seq_data/GONe/EV/EV_9_sample_biallele_noindel_filtered.ped
# .map file should be in the same directory

gone2path=/mnt/hdd/Rayis/softs/GONE2/gone2

outpath=/media/birdlab/HDD_16/raw_seq_data/GONe/EV/bootstraps


# ============================================================
# GONE2 parameters
# ============================================================

n_boot=100

ulimit -s unlimited


# ============================================================
# Run GONE2 bootstrap replicates
# ============================================================

for i in {0..100}; do

    $gone2path \
        -r 1 \
        -o $outpath/EV_final_boot${i} \
        $pedfile \
        -t 20

done
