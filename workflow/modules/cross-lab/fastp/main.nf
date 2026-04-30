process FASTP {
    tag "${sample_id}"
    container "\$projectDir/containers/fastp.sif"
    publishDir "${params.outdir}/fastp", mode: 'copy'

    input:
    tuple val(sample_id), path(files)
    val(single_end)

    output:
    tuple val(sample_id),
          path("${sample_id}_R1.trimmed.fastq.gz"),
          path("${sample_id}_R2.trimmed.fastq.gz"),
          path("${sample_id}.fastp.json"),
          path("${sample_id}.fastp.html"),
          emit: fastp_trimmed

    script:
    if (single_end)
        """
        echo "Started FASTP trimming of sample ${sample_id} (single-end)"

        fastp \
            -i ${files[0]} \
            -o ${sample_id}_R1.trimmed.fastq.gz \
            -j ${sample_id}.fastp.json \
            -h ${sample_id}.fastp.html \
            --thread ${task.cpus ?: 4}

        # Create empty R2 placeholder so output tuple is consistent
        touch ${sample_id}_R2.trimmed.fastq.gz
        """
    else
        """
        echo "Started FASTP trimming of sample ${sample_id} (paired-end)"

        fastp \
            -i ${files[0]} \
            -I ${files[1]} \
            -o ${sample_id}_R1.trimmed.fastq.gz \
            -O ${sample_id}_R2.trimmed.fastq.gz \
            -j ${sample_id}.fastp.json \
            -h ${sample_id}.fastp.html \
            --thread ${task.cpus ?: 4}
        """
}