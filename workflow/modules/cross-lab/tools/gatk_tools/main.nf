process PREPARE_REFERENCE {
    tag "${fasta.simpleName}"
    publishDir "${params.outdir}/reference", mode: 'copy'

    input:
    tuple val(ref_name), path(fasta)

    output:
    tuple path(fasta), path("${fasta}.fai"), path("${fasta.baseName}.dict"), emit: bundle

    script:
    """
    samtools faidx ${fasta}
    gatk CreateSequenceDictionary -R ${fasta} -O ${fasta.baseName}.dict
    """
}

process BASE_RECALIBRATOR {
    tag "${sxr_prefix}"

    input:
    tuple val(sample_id), path(bam), path(bai), 
          path(ref), path(ref_fai), path(ref_dict),
          val(sxr_prefix)
    path known_sites
    path known_sites_idx

    output:
    tuple val(sample_id), path("${sxr_prefix}_recal_data.table"), 
          val(sxr_prefix), emit: table

    script:
    """
    gatk BaseRecalibrator \
        -R ${ref} \
        -I ${bam} \
        --known-sites ${known_sites} \
        -O ${sxr_prefix}_recal_data.table
    """
}

process APPLY_BQSR {
    tag "${sxr_prefix}"

    input:
    tuple val(sample_id), path(bam), path(bai),
          path(ref), path(ref_fai), path(ref_dict),
          val(sxr_prefix), path(recal_table)

    output:
    tuple val(sample_id), path("${sxr_prefix}.recal.bam"), 
          path("${sxr_prefix}.recal.bai"), val(sxr_prefix), emit: bam

    script:
    """
    gatk ApplyBQSR \
        -R ${ref} \
        -I ${bam} \
        --bqsr-recal-file ${recal_table} \
        -O ${sxr_prefix}.recal.bam \
        --create-output-bam-index true
    """
}

process HAPLOTYPE_CALLER {
    tag "$meta.id"
    publishDir "${params.outdir}/variants", mode: 'copy'
    cpus 4

    input:
    tuple val(meta), path(bam), path(bai), path(ref_fasta)

    output:
    tuple val(meta), path("${meta.id}.raw.vcf.gz"), 
          path("${meta.id}.raw.vcf.gz.tbi"),
          path(ref_fasta), path("*.fai"), path("*.dict"), emit: vcf

    script:
    """
    samtools faidx ${ref_fasta}
    gatk CreateSequenceDictionary -R ${ref_fasta} -O ${ref_fasta.baseName}.dict
    gatk HaplotypeCaller \
        -R ${ref_fasta} \
        -I ${bam} \
        -O ${meta.id}.raw.vcf.gz \
        --native-pair-hmm-threads ${task.cpus}
    """
}

process SELECT_SNPS {
    tag "${meta}"
    cpus 2

    input:
    tuple val(meta), path(vcf), path(tbi), 
          path(ref_fasta), path(ref_fai), path(ref_dict)

    output:
    tuple val(meta), path("${meta.id}.snps.vcf.gz"),
          path("${meta.id}.snps.vcf.gz.tbi"),
          path(ref_fasta), path(ref_fai), path(ref_dict), emit: snps

    script:
    """
    gatk SelectVariants \
        -R ${ref_fasta} \
        -V ${vcf} \
        --select-type-to-include SNP \
        -O ${meta.id}.snps.vcf.gz
    """
}

process SELECT_INDELS {
    tag "${meta}"
    cpus 2

    input:
    tuple val(meta), path(vcf), path(tbi), path(ref_fasta), path(ref_fai), path(ref_dict)

    output:
    tuple val(meta), path("${meta.id}.indels.vcf.gz"),
          path("${meta.id}.indels.vcf.gz.tbi"),
          path(ref_fasta), path(ref_fai), path(ref_dict), emit: indels

    script:
    """
    gatk SelectVariants \
        -R ${ref_fasta} \
        -V ${vcf} \
        --select-type-to-include INDEL \
        -O ${meta.id}.indels.vcf.gz
    """
}

process FILTER_SNPS {
    tag "${meta}"
    cpus 2

    input:
    tuple val(meta), path(vcf), path(tbi),
          path(ref_fasta), path(ref_fai), path(ref_dict)

    output:
    tuple val(meta), path("${meta.id}.snps.filtered.vcf.gz"),
          path("${meta.id}.snps.filtered.vcf.gz.tbi"), emit: filtered_snps

    script:
    """
    gatk VariantFiltration \
        -R ${ref_fasta} \
        -V ${vcf} \
        --filter-expression "QD < 2.0" --filter-name "LowQD" \
        --filter-expression "FS > 60.0" --filter-name "HighFS" \
        --filter-expression "MQ < 40.0" --filter-name "LowMQ" \
        --filter-expression "SOR > 3.0" --filter-name "HighSOR" \
        --filter-expression "ReadPosRankSum < -8.0" --filter-name "LowReadPosRankSum" \
        --filter-expression "MQRankSum < -12.5" --filter-name "LowMQRankSum" \
        -O ${meta.id}.snps.filtered.vcf.gz
    """
}

process FILTER_INDELS {
    tag "${meta}"
    cpus 2

    input:
    tuple val(meta), path(vcf), path(tbi),
          path(ref_fasta), path(ref_fai), path(ref_dict)

    output:
    tuple val(meta), path("${meta.id}.indels.filtered.vcf.gz"),
          path("${meta.id}.indels.filtered.vcf.gz.tbi"), emit: filtered_indels

    script:
    """
    gatk VariantFiltration \
        -R ${ref_fasta} \
        -V ${vcf} \
        --filter-expression "QD < 2.0" --filter-name "LowQD" \
        --filter-expression "FS > 200.0" --filter-name "HighFS" \
        --filter-expression "SOR > 10.0" --filter-name "HighSOR" \
        --filter-expression "ReadPosRankSum < -20.0" --filter-name "LowReadPosRankSum" \
        -O ${meta.id}.indels.filtered.vcf.gz
    """
}

process MERGE_FILTERED_VARIANTS {
    tag "${meta}"
    publishDir "${params.outdir}/variants_filtered", mode: 'copy'
    cpus 2

    input:
    tuple val(meta),
    path(snps_vcf), 
    path(snps_tbi)
    
    tuple val(meta2),
    path(indels_vcf),
    path(indels_tbi)

    output:
    tuple val(meta), path("${meta.id}-${meta.ref2}.vcf.gz"),
          path("${meta.id}-${meta.ref2}.vcf.gz.tbi"),  emit: merged

    script:
    """
    gatk MergeVcfs \
        -I ${snps_vcf} \
        -I ${indels_vcf} \
        -O ${meta.id}-${meta.ref2}.vcf.gz
    """
}

process SELECT_PASSING {
    tag "${meta}"
    cpus 2

    input:
    tuple val(meta), path(vcf), path(tbi)

    output:
    tuple val(meta), path("${meta.id}-${meta.ref2}_pass.vcf.gz"),
          path("${meta.id}-${meta.ref2}_pass.vcf.gz.tbi"), emit: pass_vcf

    script:
    """
    gatk SelectVariants \
        -V ${vcf} \
        --exclude-filtered \
        -O ${meta.id}-${meta.ref2}_pass.vcf.gz
    """
}

process COVERAGE_MASK {
    tag "${meta}"
    publishDir "${params.outdir}/coverage", mode: 'copy'
    cpus 2

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}.low_coverage.bed"), emit: mask

    script:
    """
    bedtools genomecov -ibam ${bam} -d > ${meta.id}.depth.txt

    awk -v OFS='\t' '\$3 < ${params.qc.min_depth} {print \$1, \$2-1, \$2}' \
        ${meta.id}.depth.txt > ${meta.id}.low_coverage_raw.bed

    bedtools merge -i ${meta.id}.low_coverage_raw.bed \
        > ${meta.id}.low_coverage.bed

    rm -f ${meta.id}.depth.txt ${meta.id}.low_coverage_raw.bed
    """
}

process CONSENSUS {
    tag "${meta.id}-${meta.ref2}"
    publishDir "${params.outdir}/consensus", mode: 'copy'
    cpus 2

    input:
    tuple val(meta),
    path(vcf),
    path(tbi)
    
    tuple val (meta2), 
    path(mask_bed)

    tuple val (meta3),
    path(bam),
    path(bai),
    path(ref_fasta)

    output:
    tuple val(meta), path("${meta.id}-${meta.ref2}.consensus.fasta"), emit: fasta

    script:
    """
    bcftools consensus \
        -f ${ref_fasta} \
        -m ${mask_bed} \
        ${vcf} \
    | sed 's/^>.*/>${meta.id}-${meta.ref2}/' \
    > ${meta.id}-${meta.ref2}.consensus.fasta
    """
}