process REPORT_COMPILATION {
    tag "$sample_id"
    cpus 4
    publishDir "${params.outdir}/report", mode: 'copy'

    input:
    tuple val(sample_id), path(raw), path(trimmed), path(wf_metrics), path(marked_dup), path(marked_dup_index)

    output:
    tuple path("${sample_id}_report_part.csv"), path("${sample_id}_coverage_report.pdf"), emit: report_part

    script:
    """
    export MPLCONFIGDIR=/scratch/hsommer/matplotlib
    mkdir -p \$MPLCONFIGDIR
    python3 ${workflow.projectDir}/modules/bin/report_compiler.py ${raw} ${trimmed} ${wf_metrics} ${sample_id}
    python3 ${workflow.projectDir}/modules/bin/coverage_gen.py ${marked_dup} ${marked_dup_index}
    """
}