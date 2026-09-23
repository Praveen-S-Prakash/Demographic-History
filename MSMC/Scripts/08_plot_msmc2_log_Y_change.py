#!/usr/bin/env python3

# MSMC2 - Plot demographic history
#
# This script reads the MSMC2 output for Themeda triandra,
# converts MSMC2 time boundaries to years ago, calculates
# effective population size, and generates a log-log plot.
#
# A full demographic history plot is also retained as a
# commented-out option.


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Mutation rate and generation time
mu = 1e-08
gen = 1

# Directory containing MSMC2 output
dir_ = "/media/birdlab/HDD_16/raw_seq_data/MSMC/TT"

# MSMC2 output
msmc_out = pd.read_csv(
    "{}/TT_msmc2_phased_TT_out.final.txt".format(dir_),
    sep='\t',
    header=0
)

# Convert MSMC2 time boundaries to years ago
t_years = (
    gen *
    (msmc_out.left_time_boundary + msmc_out.right_time_boundary) / 2
    / mu
)

# Calculate Ne
Ne = (1 / msmc_out["lambda"]) / (2 * mu)


# ============================================================
# PLOT 1: FULL DEMOGRAPHIC HISTORY
# ============================================================

#plt.figure(figsize=(8, 6))

#plt.semilogx(
 #   t_years,
  #  Ne,
# drawstyle='steps',
#    color="#7B2CBF",
#    label='T. triandra'
#)

#plt.xlabel("Years ago")
#plt.ylabel("Effective population size (Ne)")
#plt.legend()

#plt.tight_layout()

#plt.savefig(
#    "{}/TT_9ind_MSMC2_full.pdf".format(dir_),
#    bbox_inches='tight'
#)

#plt.show()


# ============================================================
# PLOT 2: ZOOMED-IN VIEW
# ============================================================
plt.figure(figsize=(8, 6))

plt.loglog(
    t_years,
    Ne,
    drawstyle='steps',
    color="#7B2CBF",
    label='T. triandra'
)

plt.xlabel("Years ago")
plt.ylabel("Effective population size (Ne)")
plt.legend()

plt.tight_layout()

plt.savefig(
    "{}/TT_9ind_MSMC2_loglog.pdf".format(dir_),
    bbox_inches='tight'
)

plt.show()
