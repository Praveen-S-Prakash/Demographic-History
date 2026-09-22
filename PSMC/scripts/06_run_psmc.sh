#!/bin/bash

set -e  # Exit immediately if any command fails

# ============================================================
# PSMC analysis - TT_02
# ============================================================
#
# Purpose:
#   Convert a diploid consensus FASTQ to PSMC format,
#   run PSMC, generate bootstrap replicates, combine results,
#   and generate demographic history plots.
#
# ============================================================


# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

indir="/media/birdlab/HDD_16/raw_seq_data/NCGM_5022/PSMC/"

outdir="/media/birdlab/HDD_16/raw_seq_data/NCGM_5022/PSMC/PSMC_out/TT_02"

fq="$indir/60707400250-AVL-TT-0626-02-NCGM-5022_L001_filtered_sorted_diploid.fq.gz"

psmcfa="$outdir/60707400250-AVL-TT-0626-02-NCGM-5022_L001_filtered_sorted_diploid.psmcfa"

split_psmcfa="$outdir/60707400250-AVL-TT-0626-02-NCGM-5022_L001_filtered_sorted_diploid_split.psmcfa"

psmc_bin="/home/birdlab/softs/psmc"

utils="$psmc_bin/utils"

outprefix="60707400250-AVL-TT-0626-02-NCGM-5022_L001_filtered_sorted_diploid"

psmc_out="$outdir/${outprefix}.psmc"

psmc_comb="$outdir/${outprefix}_combined.psmc"

email="praveenprakash@labs.iisertirupati.ac.in"


# ------------------------------------------------------------
# 2. Create output directories
# ------------------------------------------------------------

mkdir -p "$outdir" "$outdir/boots"


# ------------------------------------------------------------
# 3. PSMC parameters
# ------------------------------------------------------------

N=25
t=9
r=5
p="26*2+4+7+1"

mu=0.41e-08
gen_time=1


# ------------------------------------------------------------
# 4. Convert FASTQ to PSMC input format
# ------------------------------------------------------------

echo "Generating PSMCFA..."

"$utils/fq2psmcfa" -q20 "$fq" > "$psmcfa"


# ------------------------------------------------------------
# 5. Run initial PSMC
# ------------------------------------------------------------

echo "Running initial PSMC..."

"$psmc_bin/psmc" \
    -N$N \
    -t$t \
    -r$r \
    -p "$p" \
    -o "$psmc_out" \
    "$psmcfa"


# ------------------------------------------------------------
# 6. Generate PSMC history and ms command
# ------------------------------------------------------------

echo "Generating simulated ms command..."

"$utils/psmc2history.pl" "$psmc_out" | \
    "$utils/history2ms.pl" > "$outdir/ms-cmd.sh"


# ------------------------------------------------------------
# 7. Generate bootstrap replicates
# ------------------------------------------------------------

echo "Bootstrapping..."

"$utils/splitfa" "$psmcfa" > "$split_psmcfa"

seq 100 | parallel -j 20 \
    "$psmc_bin/psmc -N$N -t$t -r$r -b -p \"$p\" -o \"$outdir/boots/${outprefix}_round-{}.psmc\" \"$split_psmcfa\""


# ------------------------------------------------------------
# 8. Combine PSMC outputs
# ------------------------------------------------------------

echo "Combining bootstrapped PSMC outputs..."

cat "$psmc_out" \
    "$outdir/boots/${outprefix}_round-"*.psmc \
    > "$psmc_comb"


# ------------------------------------------------------------
# 9. Plot PSMC results
# ------------------------------------------------------------

echo "Plotting PSMC results..."

# Plot without -pY scaling
"$utils/psmc_plot.pl" \
    -S \
    -R \
    -u "$mu" \
    -g "$gen_time" \
    "$outdir/${outprefix}_no_scaling" \
    "$psmc_out"


# Plot with -pY50000 scaling
"$utils/psmc_plot.pl" \
    -R \
    -u "$mu" \
    -g "$gen_time" \
    -pY50000 \
    "$outdir/${outprefix}" \
    "$psmc_comb"


echo "PSMC pipeline completed at $(date)"
