process CONSENSUS {
    publishDir "${params.outdir}/consensus", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path("*.fa")

    script:
    """
    samtools mpileup -A -a -d 0 -Q 0 ${bam} | ivar consensus -p ${meta.id} -t 0.5 -m 10 -n N
    """
}