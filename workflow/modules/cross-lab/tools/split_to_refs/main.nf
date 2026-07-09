process SPLIT_TO_REFS {
    tag "$meta.id"

    publishDir "${params.outdir}/split_bams", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.sorted.marked.bam"), path("*.sorted.marked.bam.bai"),
    emit: split_bams

    script:
    """
    for chr in \$(samtools view -H ${bam} | grep "^@SQ" | cut -f 2 | cut -f 2- -d ':'); do
        samtools view -bh ${bam} "\$chr" > "\${chr}.sorted.marked.bam"
        samtools index "\${chr}.sorted.marked.bam"
    done
    """

    // bam
    // sorted
    // indexed
}