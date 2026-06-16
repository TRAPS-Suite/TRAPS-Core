process CONCATENATE_REFERENCES {
    publishDir "${params.outdir}/bwamem2_indexes", mode: 'copy'
    
    input:
    path(reference_files)
    
    output:
    path("concatenated_references.fasta"), emit: fasta
    
    script:
    """
    cat ${reference_files} > concatenated_references.fasta
    """
}

process BWAMEM2_INDEX {
    tag "$ref_name_formatted"
    publishDir "${params.outdir}/bwamem2_indexes", mode: 'copy'

    input:
    tuple val(ref_name), val(ref_name_formatted), path(ref_path)

    output:
    tuple path("*.amb"),
          path("*.ann"),
          path("*.pac"),
          path("*.0123"),
          path("*.bwt.2bit.64"),
          emit: bm2_index_bundle

    script:
    """
    bwa-mem2 index -p ${ref_name_formatted} ${ref_path}
    """
}


process BWAMEM2 {
    tag "$meta.id"
    publishDir "${params.outdir}/bwamem2", mode: 'copy'

    input:
    tuple val(meta), path(reads), val(ref_name_formatted), path(ref_path)

    output:
    tuple val(meta), path("*.bam"), path("*.bam.bai"), val(ref_name_formatted), path(ref_path), emit: aligned_sxr

    script:
    def paired = reads instanceof List && reads.size() == 2
    def read_args = paired ? "${reads[0]} ${reads[1]}" : "${reads[0]}"
    
    """
    bwa-mem2 mem \\
        -t ${task.cpus} \\
        -R '@RG\tID:Group1\tSM:SampleA\tPL:ILLUMINA\tLB:Lib1' \\
        -p "${params.outdir}/bwamem2_indexes/${ref_name_formatted}" \\
        ${read_args} | \\
        samtools sort -@ ${task.cpus} -o ${meta.id}_${ref_name_formatted}.sorted.bam
    
    samtools index ${meta.id}_${ref_name_formatted}.sorted.bam
    """
}