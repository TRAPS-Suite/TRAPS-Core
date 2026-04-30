process RAW_METRICS {
    debug true
    tag "$sample_id"
    container "$projectDir/containers/samtools.sif"
    publishDir "${params.outdir}/workflow_metrics/raw_metrics", mode: 'copy'

    input:
    tuple val(sample_id), path(r1), path(r2)

    output:
    tuple val(sample_id), path("*.tsv"), emit: raw_metrics_out

    script:
    """
    set -euo pipefail
    raw_reads=\$(zcat ${r1} | awk 'END {print NR/4}')

    echo -e "${sample_id}\\t\$raw_reads" > ${sample_id}_raw_reads.tsv
    """
}