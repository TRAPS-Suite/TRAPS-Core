    process MERGE_LANES {

    tag "$sample_id"

    input:
    tuple val(sample_id), path(r1_files), path(r2_files)

    output:
    tuple val(sample_id),
          path("${sample_id}_R1_merged.fastq.gz"),
          path("${sample_id}_R2_merged.fastq.gz")

    script:
    """
    cat ${r1_files.join(' ')} > ${sample_id}_R1_merged.fastq.gz
    cat ${r2_files.join(' ')} > ${sample_id}_R2_merged.fastq.gz
    """
}