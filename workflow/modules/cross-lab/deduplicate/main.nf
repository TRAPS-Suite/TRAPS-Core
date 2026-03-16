process DEDUPLICATE {
    memory '16 GB'
    tag "${sample_id}"
    container "$projectDir/containers/picard.sif"
    publishDir "${params.outdir ?: 'results'}/markduplicates", mode: 'copy'

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}.marked.bam"), path("${sample_id}.marked.bam.bai"), emit: marked_bam

    script:
    """
    picard MarkDuplicates \
        I=${bam} \
        O=${sample_id}.marked.bam \
        M=${sample_id}.dup_metrics.txt \
        REMOVE_DUPLICATES=false \
        CREATE_INDEX=true \
        VALIDATION_STRINGENCY=SILENT
    picard BuildBamIndex \
        I=${sample_id}.marked.bam \
        O=${sample_id}.marked.bam.bai
    """
}
