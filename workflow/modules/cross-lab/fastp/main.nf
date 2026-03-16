process FASTP {
    tag "$sample_id"
    container "$projectDir/containers/fastp.sif"
    publishDir "${params.outdir ?: 'results'}/qc", mode: 'copy'

    input:
    tuple val(sample_id), path(r1), path(r2)

    output:
    tuple val(sample_id),
          path("${sample_id}_R1.trimmed.fastq.gz"),
          path("${sample_id}_R2.trimmed.fastq.gz"),
          path("${sample_id}.fastp.json"),
          path("${sample_id}.fastp.html")

    script:
    """
    fastp \
        -i ${r1} \
        -I ${r2} \
        -o ${sample_id}_R1.trimmed.fastq.gz \
        -O ${sample_id}_R2.trimmed.fastq.gz \
        -j ${sample_id}.fastp.json \
        -h ${sample_id}.fastp.html \
        --thread ${task.cpus ?: 4}
    """
}
