#!/bin/bash

# ============================================================
# Trimmomatic paired-end read trimming
# ============================================================
#
# Purpose:
#   Trim adapter sequences and low-quality bases from paired-end
#   FASTQ files using Trimmomatic.
#
# Input:
#   Raw paired-end FASTQ files
#
# Output:
#   Paired and unpaired trimmed FASTQ files
#
# ============================================================

# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

# Trimmomatic software directory
softpath="/home/birdlab/softs/Trimmomatic-0.39/"

# Input raw FASTQ files
inpath="/mnt/SERB_NAS_Biogeography/raw-genomics/NCGM-5023/"

# Output trimmed FASTQ files
outpath="/media/birdlab/HDD_16/raw_seq_data/NCGM_5023/trimmed_files/"

# Directory for trimming summary logs
trimpath="/media/birdlab/HDD_16/raw_seq_data/NCGM_5023/trim_logs/"

# Email address for notifications
email="praveenprakash@labs.iisertirupat.ac.in"


# ------------------------------------------------------------
# 2. Create output directories
# ------------------------------------------------------------

mkdir -p "$outpath"
mkdir -p "$trimpath"


# ------------------------------------------------------------
# 3. Send trimming-start notification
# ------------------------------------------------------------

echo "Starting trimming at $(date)" | \
    mail -s "Trimming Started" "$email"


# ------------------------------------------------------------
# 4. Trim paired-end FASTQ files
# ------------------------------------------------------------

for i in "$inpath"*"_R1_001.fastq.gz"; do

    file=$(basename "$i" _R1_001.fastq.gz)

    echo "$file"

    /usr/lib/jvm/java-17-openjdk-amd64/bin/java \
        -jar "$softpath"trimmomatic-0.39.jar PE \
        -phred33 \
        -threads 10 \
        -summary "$trimpath$file.txt" \
        "$inpath$file"_R1_001.fastq.gz \
        "$inpath$file"_R2_001.fastq.gz \
        "$outpath$file"_R1_paired.fastq.gz \
        "$outpath$file"_R1_unpaired.fastq.gz \
        "$outpath$file"_R2_paired.fastq.gz \
        "$outpath$file"_R2_unpaired.fastq.gz \
        ILLUMINACLIP:"$softpath"adapters/TruSeq3-PE.fa":2:30:10:2:True \
        LEADING:3 \
        TRAILING:3 \
        MINLEN:36

done


# ------------------------------------------------------------
# 5. Send trimming-completed notification
# ------------------------------------------------------------

echo "Trimming completed at $(date)" | \
    mail -s "Trimming Finished" "$email"
```

