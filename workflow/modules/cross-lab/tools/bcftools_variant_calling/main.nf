process BCF_CALL_VARIANTS {
    tag "$meta.id"
    publishDir "${params.outdir}/variants", mode: 'copy'
   
    input:
    tuple val(meta), path(bam), path(bai), val(ref_name), path(ref_path)

    output:
    tuple val(meta), path("${meta.id}_${ref_name}.vcf.gz*"), val(ref_name), path(ref_path), emit: vcf

    script:
    """
    bedtools genomecov -ibam ${bam} -bga | awk '\$4 < 10' > ${meta.id}_low_coverage.bed
    bedtools maskfasta -fi ${ref_path} -bed ${meta.id}_low_coverage.bed -fo masked_reference.fasta

    bcftools mpileup -f masked_reference.fasta -Ou ${bam} | \\
    bcftools call -mv -Oz -o ${meta.id}_${ref_name}.vcf.gz
    """
}

process BCF_FILTER_VARIANTS {
    tag "$meta.id"
    publishDir "${params.outdir}/filtered_variants", mode: 'copy'
    
    input:
    tuple val(meta), path(unfiltered_vcf), val(ref_name), path(ref_path)

    output:
    tuple val(meta), path("${meta.id}_${ref_name}.vcf.gz"), path("${meta.id}_${ref_name}.vcf.gz.tbi"), val(ref_name), path(ref_path), emit: vcf

    script:
    """
    bcftools filter -i 'QUAL > 20 && DP > 10' ${unfiltered_vcf} -Oz -o ${meta.id}_${ref_name}.vcf.gz
    tabix -p vcf ${meta.id}_${ref_name}.vcf.gz
    """
}

process CONSENSUS_SEQUENCE {
    tag "$meta.id"
    publishDir "${params.outdir}/consensus", mode: 'copy'
    
    input:
    tuple val(meta), path(vcf), path(vcf_index), val(ref_name), path(ref_path)

    output:
    tuple val(meta), path("${meta.id}_${ref_name}_consensus.fasta"), val(ref_name), emit: consensus

    script:
    """
    bcftools consensus -f ${ref_path} ${vcf} > ${meta.id}_${ref_name}_consensus.fasta
    
    sed -i 's/^>.*/>${meta.id}_${ref_name}/' ${meta.id}_${ref_name}_consensus.fasta
    """
}