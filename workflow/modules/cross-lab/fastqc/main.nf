process FASTQC {
    tag "$sample_id"
    container "$projectDir/containers/fastqc.sif"
    publishDir "${params.outdir ?: 'results'}/fastqc", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}_R*_fastqc.html"), emit: fastqc_report_html

    script:
    """
    fastqc ${reads[0]} ${reads[1]}
    """
}
