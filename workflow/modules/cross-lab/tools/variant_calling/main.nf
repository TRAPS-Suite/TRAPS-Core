process VARIANT_CALL {
    tag "$meta.id"
    publishDir "${params.outdir}/variant_calling", mode: 'copy'

    input:
    tuple val(meta), path(sorted_bam), path(bai), val(ref_name), path(ref_path)

    output:
    tuple val(meta), path("*filtered_variants.vcf.gz"), path("*filtered_variants.vcf.gz.csi"), path(ref_path), val(ref_name), emit: variants_out

    script:
    """
    bcftools mpileup \
        -Ou \
        -f ${ref_path} \
        ${sorted_bam} \
    | bcftools call \
        -mv \
        -Oz \
        -o ${meta.id}_${ref_name}_raw_variants.vcf.gz
    bcftools index ${meta.id}_${ref_name}_raw_variants.vcf.gz

    bcftools filter \
        -i 'QUAL>30 && INFO/DP>10' \
        ${meta.id}_${ref_name}_raw_variants.vcf.gz \
        -Oz -o ${meta.id}_${ref_name}_filtered_variants.vcf.gz
    bcftools index ${meta.id}_${ref_name}_filtered_variants.vcf.gz
    """
}

process BED_MASK {
    tag "$meta.id"
    publishDir "${params.outdir}/variant_calling", mode: 'copy'

    input:
    tuple val(meta), path(sorted_bam), path(bai), val(ref_name), path(ref_path)

    output:
    tuple val(meta), path("*lowcov.bed"), emit: mask_out

    script:
    """
    samtools depth -aa ${sorted_bam} > depth.txt
    awk '\$3 < 10 {
    print \$1"\t"\$2-1"\t"\$2
    }' depth.txt > ${meta.id}_${ref_name}_lowcov.bed
    """
}

process GENERATE_CONSENSUS {
    tag "$meta.id"
    publishDir "${params.outdir}/variant_calling", mode: "copy"

    input:
    tuple val(meta), path(variants), path(variants_index), path(ref_path), val(ref_name)
    tuple val(meta2), path(mask)
    output:
    tuple val(meta), path("*consensus.fasta")
    script:
    """
    bcftools consensus \
    -f ${ref_path} \
    -m ${mask} \
    ${variants} \
    > ${meta.id}_${ref_name}_consensus.fasta
    """
}