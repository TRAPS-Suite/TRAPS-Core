process CLEAN_REF {
    publishDir "${params.outdir}/bwamem2", mode: 'copy'
    
    input:
    tuple val(ref_name), val(ref_name_formatted), path(ref_path)

    output:
    path("*.fasta"), emit: fasta
    
    script:
    """
    sed 's/^>.*/>${ref_name_formatted}/' ${ref_path} > ${ref_name_formatted}.fasta
    """
}

process BWAMEM2_INDEX {
    publishDir "${params.outdir}/bwamem2", mode: 'copy'

    input:
    path(fasta)

    output:
    tuple path("*.amb"),
          path("*.ann"),
          path("*.pac"),
          path("*.0123"),
          path("*.bwt.2bit.64"),
          emit: bm2_index_bundle

    script:
    """
    cat ${fasta} > combined_fasta.fasta
    bwa-mem2 index -p index combined_fasta.fasta
    """
}


process BWAMEM2 {
    tag "$meta.id"
    publishDir "${params.outdir}/bwamem2", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.bam"), path("*.bam.bai"), emit: aligned

    script:
    def paired = reads instanceof List && reads.size() == 2
    def read_args = paired ? "${reads[0]} ${reads[1]}" : "${reads[0]}"
    
    """
    bwa-mem2 mem \\
        -t ${task.cpus} \\
        -R '@RG\tID:Group1\tSM:SampleA\tPL:ILLUMINA\tLB:Lib1' \\
        -p "${params.outdir}/bwamem2/index" \\
        ${read_args} | \\
        samtools sort -@ ${task.cpus} -o ${meta.id}.sorted.bam
    
    samtools index ${meta.id}.sorted.bam
    """
}