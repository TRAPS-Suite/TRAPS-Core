process DEDUPED_METRICS {
    debug true
    tag "$sample_id"
    container "$projectDir/../containers/samtools.sif"
    publishDir "${params.outdir}/workflow_metrics/deduped_metrics", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    tuple val(sample_id), path("*.tsv"), emit: workflow_metrics_out

    script:
    """
    samtools coverage -H ${bam} | awk '{print "${sample_id}" "\t" \$1 "\t" \$4 "\t" \$6 "\t" \$7}' > ${sample_id}_deduped_metrics.tsv
    """
}