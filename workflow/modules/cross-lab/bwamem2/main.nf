process BWAMEM2 {
    debug true
    tag "$sample_id"
    container "$projectDir/containers/bwa-mem2.sif"
    publishDir "${params.outdir ?: 'results'}/bwamem2", mode: 'copy'

    input:
    tuple val(sample_id), path(r1), path(r2), path(json), path(html)

    output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai")
    script:
    """
    bwa-mem2 mem -t ${task.cpus} -R "@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA" /work/crosslab/hsommer/trapseq/indexes/bwamem2_indexes/zika_wnv_index ${r1} ${r2} | \
            samtools sort -o ${sample_id}.sorted.bam
    samtools index ${sample_id}.sorted.bam
    """
}