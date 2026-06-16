// May 27 2026
process FULL_RUN_METRIC_TABLE_GEN {
    tag "$sample_id"
    cpus 4
    publishDir "${params.outdir}/reports", mode: 'copy'

    input:
    tuple val(sample_id), path(raw), path(trimmed), path(wf_metrics), path(marked_dup), path(marked_dup_index)

    output:
    path("${params.outdir}/reports/metrics_table.csv")

    script:
    """
    python3 ${workflow.projectDir}/modules/bin/metrics_table_gen.py ${params.outdir}/metrics ${params.outdir}/reports
    """
}