process DEDUPLICATE {
    memory '16 GB'
    tag "$meta.id"
    publishDir "${params.outdir}/markduplicates", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai), val(ref_name), path(ref_path)

    output:
    tuple val(meta), path("*.sorted.marked.bam"), path("*.sorted.marked.bai"), val(ref_name), path(ref_path), emit: marked_sxr
          

    script:
    """
    picard MarkDuplicates \
        -I ${bam} \
        -O ${meta.id}_${ref_name}.sorted.marked.bam \
        -M ${meta.id}_${ref_name}.dup_metrics.txt \
        --REMOVE_DUPLICATES false \
        --CREATE_INDEX true \
        --VALIDATION_STRINGENCY SILENT
    """
}