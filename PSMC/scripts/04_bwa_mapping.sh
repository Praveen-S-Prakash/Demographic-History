#!/bin/bash

set -e  # Exit if any command fails

# ============================================================
# BWA MEM mapping, BAM filtering, sorting and duplicate removal
# ============================================================
#
# Purpose:
#   Map paired-end Illumina reads to the reference genome,
#   filter reads by mapping quality, sort BAM files, remove
#   PCR duplicates, and index the final BAM files.
#
# Input:
#   Trimmed paired-end FASTQ files
#
# Output:
#   Mapped BAM files
#   MAPQ-filtered BAM files
#   Sorted BAM files
#   Duplicate-removed BAM files
#   BAM index files
#   Picard duplicate metrics
#
# ============================================================


# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

# Input trimmed FASTQ files
inpath="/media/birdlab/HDD_16/raw_seq_data/NCGM_5022/trimmed_files/"

# Output alignment directory
outpath="/media/birdlab/HDD_16/raw_seq_data/NCGM_5022/alignment_files/"

# Reference genome
reffile="/media/birdlab/HDD_16/raw_seq_data/NCGM_5022/ref_TT/ref/GCA_057662145.1_ThtriWBW_v1.0_genomic.fna"

# Email for notifications
email="praveenprakash@labs.iisertirupati.ac.in"


# ------------------------------------------------------------
# 2. Software paths
# ------------------------------------------------------------

bwa="/home/birdlab/softs/bwa/bwa"

samtools="/home/birdlab/miniconda3/envs/phyluce-1.7.3/bin/samtools"

picard="/home/birdlab/softs/picard.jar"


# ------------------------------------------------------------
# 3. Setup
# ------------------------------------------------------------

mkdir -p "$outpath" "$outpath/tmp"


# ------------------------------------------------------------
# 4. Start notification
# ------------------------------------------------------------

echo "Starting BWA MEM mapping + filtering + rmdup at $(date)" | \
    mail -s "Mapping Started" "$email"


# ------------------------------------------------------------
# 5. BWA MEM mapping and MAPQ filtering
# ------------------------------------------------------------

for i in "${inpath}"*_R1_paired.fastq.gz; do

    file=$(basename "$i" _R1_paired.fastq.gz)

    echo "Processing sample: $file"

    # --------------------------------------------------------
    # Step 1: BWA MEM mapping
    # --------------------------------------------------------

    echo "Mapping $file with BWA MEM..."

    "$bwa" mem \
        -t 20 \
        -M \
        -R "@RG\tID:${file}\tSM:${file}\tLB:IlluminaWGS\tPL:ILLUMINA" \
        "$reffile" \
        "${inpath}${file}_R1_paired.fastq.gz" \
        "${inpath}${file}_R2_paired.fastq.gz" | \
    "$samtools" view -bh - | \
    "$samtools" sort \
        -@ 20 \
        -T "${outpath}/tmp/${file}_tmp" \
        -o "${outpath}${file}_mapped.bam"

    # --------------------------------------------------------
    # Step 2: Filter by mapping quality
    # --------------------------------------------------------

    echo "Filtering $file BAM for quality >= 20"

    "$samtools" view \
        -bh \
        -F 4 \
        -q 20 \
        -o "${outpath}${file}_filtered.bam" \
        "${outpath}${file}_mapped.bam"

    # --------------------------------------------------------
    # Step 3: Final sorting
    # --------------------------------------------------------

    echo "Sorting filtered BAM for $file..."

    "$samtools" sort \
        -@ 20 \
        -T "${outpath}/tmp/${file}_sort" \
        -o "${outpath}${file}_filtered_sorted.bam" \
        "${outpath}${file}_filtered.bam"

    echo "Completed alignment + sorting for $file"

done


# ------------------------------------------------------------
# 6. Remove duplicates and index final BAM files
# ------------------------------------------------------------

echo "Starting duplicate removal for all sorted BAMs..."

for bam in "$outpath"/*_filtered_sorted.bam; do

    [ -e "$bam" ] || continue

    sample=$(basename "$bam" _filtered_sorted.bam)

    rmdup_bam="${outpath}${sample}_filtered_sorted_rmdup.bam"

    metrics_file="${outpath}${sample}_filtered_sorted_rmdup_metrics.txt"

    echo "Removing duplicates for $sample..."

    java -Xmx8g -jar "$picard" MarkDuplicates \
        MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=900 \
        INPUT="$bam" \
        OUTPUT="$rmdup_bam" \
        METRICS_FILE="$metrics_file" \
        REMOVE_DUPLICATES=true \
        ASSUME_SORTED=true \
        TMP_DIR="${outpath}/tmp" \
        VALIDATION_STRINGENCY=SILENT

    echo "Indexing $sample final BAM..."

    "$samtools" index "$rmdup_bam"

done


# ------------------------------------------------------------
# 7. Completion notification
# ------------------------------------------------------------

echo "Mapping + deduplication pipeline completed at $(date)" | \
    mail -s "Mapping Pipeline Finished" "$email"

