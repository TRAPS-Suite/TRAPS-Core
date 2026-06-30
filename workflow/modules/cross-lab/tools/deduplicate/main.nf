process DEDUPLICATE {
    memory '16 GB'
    tag "$meta.id"
    publishDir "${params.outdir}/markduplicates", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.sorted.marked.bam"), path("*.sorted.marked.bai"), emit: marked_bam
          

    script:
    """
    picard MarkDuplicates \
        -I ${bam} \
        -O ${meta.id}.sorted.marked.bam \
        -M ${meta.id}.dup_metrics.txt \
        --REMOVE_DUPLICATES false \
        --CREATE_INDEX true \
        --VALIDATION_STRINGENCY SILENT
    """
}