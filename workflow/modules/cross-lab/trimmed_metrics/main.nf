process TRIMMED_METRICS {
    debug true
    tag "$sample_id"
    container "$projectDir/containers/samtools.sif"
    publishDir "${params.outdir}/workflow_metrics/trimmed_metrics", mode: 'copy'

    input:
    tuple val(sample_id),
          path(r1),
          path(r2),
          path(fastp_json),
          path(fastp_html)


    output:
    tuple val(sample_id), path("*.tsv"), emit: trimmed_metrics_out

    script:
    """
    set -euo pipefail
    trimmed_reads=\$(zcat ${r1} | awk 'END {print NR/4}')

    echo -e "${sample_id}\\t\$trimmed_reads" > ${sample_id}_trimmed_reads.tsv
    """
}