process DEDUPLICATE {
    memory '16 GB'
    tag "${sxr_prefix}"
    container "\$projectDir/containers/picard.sif"
    publishDir "${params.outdir}/markduplicates", mode: 'copy'

    input:
    tuple val(sample_id),
          path(sorted_bam),
          path(sorted_bam_index),
          path(ref_path),
          path(ref_fai),
          path(ref_dict),
          val(sxr_prefix)

    output:
    tuple val(sample_id),
          path("${sxr_prefix}.marked.bam"),
          path("${sxr_prefix}.marked.bam.bai"),
          path(ref_path),
          path(ref_fai),
          path(ref_dict),
          val(sxr_prefix),
          emit: marked_bam

    script:
    """
    echo "Started deduplication of sample ${sample_id}, sxr ${sxr_prefix}"

    picard MarkDuplicates \
        I=${sorted_bam} \
        O=${sxr_prefix}.marked.bam \
        M=${sxr_prefix}.dup_metrics.txt \
        REMOVE_DUPLICATES=false \
        CREATE_INDEX=false \
        VALIDATION_STRINGENCY=SILENT

    picard BuildBamIndex \
        I=${sxr_prefix}.marked.bam \
        O=${sxr_prefix}.marked.bam.bai
    """
}