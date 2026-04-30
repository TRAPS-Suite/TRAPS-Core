process PREPARE_REFERENCE {
    tag "${fasta.simpleName}"
    publishDir "${params.outdir}/reference", mode: 'copy'

    input:
    tuple val(ref_name), path(fasta), val(index_prefix)

    output:
    tuple val(ref_name), path("${fasta}.fai"), path("${fasta.baseName}.dict"), emit: bundle

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
    tag "${sxr_prefix}"
    publishDir "${params.outdir}/variants", mode: 'copy'
    cpus 4

    input:
    tuple val(sample_id), 
          path(bam), path(bai),
          path(ref_fasta), path(ref_fai), path(ref_dict),
          val(sxr_prefix)

    output:
    tuple val(sample_id), path("${sxr_prefix}.raw.vcf.gz"), 
          path("${sxr_prefix}.raw.vcf.gz.tbi"), val(sxr_prefix), 
          path(ref_fasta), path(ref_fai), path(ref_dict), emit: vcf

    script:
    """
    gatk HaplotypeCaller \
        -R ${ref_fasta} \
        -I ${bam} \
        -O ${sxr_prefix}.raw.vcf.gz \
        --native-pair-hmm-threads ${task.cpus}
    """
}

process SELECT_SNPS {
    tag "${sxr_prefix}"
    cpus 2

    input:
    tuple val(sample_id), path(vcf), path(tbi), val(sxr_prefix),
          path(ref_fasta), path(ref_fai), path(ref_dict)

    output:
    tuple val(sample_id), path("${sxr_prefix}.snps.vcf.gz"),
          path("${sxr_prefix}.snps.vcf.gz.tbi"), val(sxr_prefix),
          path(ref_fasta), path(ref_fai), path(ref_dict), emit: snps

    script:
    """
    gatk SelectVariants \
        -R ${ref_fasta} \
        -V ${vcf} \
        --select-type-to-include SNP \
        -O ${sxr_prefix}.snps.vcf.gz
    """
}

process SELECT_INDELS {
    tag "${sxr_prefix}"
    cpus 2

    input:
    tuple val(sample_id), path(vcf), path(tbi), val(sxr_prefix),
          path(ref_fasta), path(ref_fai), path(ref_dict)

    output:
    tuple val(sample_id), path("${sxr_prefix}.indels.vcf.gz"),
          path("${sxr_prefix}.indels.vcf.gz.tbi"), val(sxr_prefix),
          path(ref_fasta), path(ref_fai), path(ref_dict), emit: indels

    script:
    """
    gatk SelectVariants \
        -R ${ref_fasta} \
        -V ${vcf} \
        --select-type-to-include INDEL \
        -O ${sxr_prefix}.indels.vcf.gz
    """
}

process FILTER_SNPS {
    tag "${sxr_prefix}"
    cpus 2

    input:
    tuple val(sample_id), path(vcf), path(tbi), val(sxr_prefix),
          path(ref_fasta), path(ref_fai), path(ref_dict)

    output:
    tuple val(sample_id), path("${sxr_prefix}.snps.filtered.vcf.gz"),
          path("${sxr_prefix}.snps.filtered.vcf.gz.tbi"), val(sxr_prefix),
          path(ref_fasta), path(ref_fai), path(ref_dict), emit: filtered_snps

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
        -O ${sxr_prefix}.snps.filtered.vcf.gz
    """
}

process FILTER_INDELS {
    tag "${sxr_prefix}"
    cpus 2

    input:
    tuple val(sample_id), path(vcf), path(tbi), val(sxr_prefix),
          path(ref_fasta), path(ref_fai), path(ref_dict)

    output:
    tuple val(sample_id), path("${sxr_prefix}.indels.filtered.vcf.gz"),
          path("${sxr_prefix}.indels.filtered.vcf.gz.tbi"), val(sxr_prefix),
          path(ref_fasta), path(ref_fai), path(ref_dict), emit: filtered_indels

    script:
    """
    gatk VariantFiltration \
        -R ${ref_fasta} \
        -V ${vcf} \
        --filter-expression "QD < 2.0" --filter-name "LowQD" \
        --filter-expression "FS > 200.0" --filter-name "HighFS" \
        --filter-expression "SOR > 10.0" --filter-name "HighSOR" \
        --filter-expression "ReadPosRankSum < -20.0" --filter-name "LowReadPosRankSum" \
        -O ${sxr_prefix}.indels.filtered.vcf.gz
    """
}

process MERGE_FILTERED_VARIANTS {
    tag "${sxr_prefix}"
    publishDir "${params.outdir}/variants_filtered", mode: 'copy'
    cpus 2

    input:
    tuple val(sample_id),
          path(snps_vcf), path(snps_tbi),
          path(indels_vcf), path(indels_tbi),
          val(sxr_prefix),
          path(ref_fasta), path(ref_fai), path(ref_dict)

    output:
    tuple val(sample_id), path("${sxr_prefix}.filtered.vcf.gz"),
          path("${sxr_prefix}.filtered.vcf.gz.tbi"), val(sxr_prefix), emit: merged

    script:
    """
    gatk MergeVcfs \
        -I ${snps_vcf} \
        -I ${indels_vcf} \
        -O ${sxr_prefix}.filtered.vcf.gz
    """
}

process SELECT_PASSING {
    tag "${sxr_prefix}"
    cpus 2

    input:
    tuple val(sample_id), path(vcf), path(tbi), val(sxr_prefix)

    output:
    tuple val(sample_id), path("${sxr_prefix}.pass.vcf.gz"),
          path("${sxr_prefix}.pass.vcf.gz.tbi"), val(sxr_prefix), emit: pass_vcf

    script:
    """
    gatk SelectVariants \
        -V ${vcf} \
        --exclude-filtered \
        -O ${sxr_prefix}.pass.vcf.gz
    """
}

process COVERAGE_MASK {
    tag "${sxr_prefix}"
    publishDir "${params.outdir}/coverage", mode: 'copy'
    cpus 2

    input:
    tuple val(sample_id), path(bam), path(bai), val(sxr_prefix)

    output:
    tuple val(sample_id), path("${sxr_prefix}.low_coverage.bed"), 
          val(sxr_prefix), emit: mask

    script:
    """
    bedtools genomecov -ibam ${bam} -d > ${sxr_prefix}.depth.txt

    awk -v OFS='\t' '\$3 < ${params.min_depth} {print \$1, \$2-1, \$2}' \
        ${sxr_prefix}.depth.txt > ${sxr_prefix}.low_coverage_raw.bed

    bedtools merge -i ${sxr_prefix}.low_coverage_raw.bed \
        > ${sxr_prefix}.low_coverage.bed

    rm -f ${sxr_prefix}.depth.txt ${sxr_prefix}.low_coverage_raw.bed
    """
}

process CONSENSUS {
    tag "${sxr_prefix}"
    publishDir "${params.outdir}/consensus", mode: 'copy'
    cpus 2

    input:
    tuple val(sample_id),
          path(vcf), path(tbi),
          path(mask_bed),
          val(sxr_prefix),
          path(ref_fasta), path(ref_fai)

    output:
    tuple val(sample_id), path("${sxr_prefix}.consensus.fasta"), 
          val(sxr_prefix), emit: fasta

    script:
    """
    bcftools consensus \
        -f ${ref_fasta} \
        -m ${mask_bed} \
        ${vcf} \
    | sed 's/^>.*/>${sxr_prefix}/' \
    > ${sxr_prefix}.consensus.fasta
    """
}