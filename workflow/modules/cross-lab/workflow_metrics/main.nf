process WORKFLOW_METRICS {
    debug true
    tag "$sample_id"
    container "$projectDir/containers/samtools.sif"
    publishDir "${params.outdir ?: 'results'}/workflow_metrics", mode: 'copy'

    input:
    tuple val(sample_id), path(input_file), val(stage)

    output:
    tuple val(sample_id), path("*.tsv"), emit: workflow_metrics_out

    script:
    """
    set -euo pipefail
    if [ "${stage}" = "raw" ]; then
        raw_reads=\$(zcat ${input_file} | awk 'END {print NR/4}')

        echo -e "${sample_id}\\t\$raw_reads" > ${sample_id}_raw_reads.tsv

    elif [ "${stage}" = "trimmed" ]; then
        trimmed_reads=\$(zcat ${input_file} | awk 'END {print NR/4}')

        echo -e "${sample_id}\\t\$trimmed_reads" > ${sample_id}_trimmed_reads.tsv
    elif [ "${stage}" = "metrics" ]; then
        #samtools idxstats ${input_file} | head -n -1 | awk '{print "${sample_id}" "\t" \$1 "\t" \$3}' > ${sample_id}_deduped_reads.tsv

        samtools coverage -H ${input_file} | awk '{print \$1 "\t" \$4 "\t" \$6 "\t" \$7}' > ${sample_id}_reference_metrics.tsv

    else
        echo "Unknown stage: ${stage}" >&2
        exit 1
    fi
    """
}