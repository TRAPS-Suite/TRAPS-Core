for r1 in /work/crosslab/hsommer/ots_data/*_R1_001.fastq.gz; do

    # Get filename only
    base=$(basename "$r1")

    # Extract prefix before first underscore
    prefix=$(echo "$base" | cut -d'_' -f1)

    # Align
    bwa-mem2 mem -t 8 \
        /work/crosslab/hsommer/TRAPS/indexes/bwamem2_indexes/culex_tarsalis_cois \
        "$r1" | \
    samtools sort -o "${prefix}.bam" -
done
