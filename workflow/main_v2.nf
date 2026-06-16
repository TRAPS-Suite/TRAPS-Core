println "========================================="
println "  TRAPS  "
println "  v4.5.0   "
println "  Date: ${new Date()}                     "
println "  Author: Henry Sommer                    "
println "========================================="
println '"To know how to wonder and question is '
println 'the first step of the mind toward discovery."'
println '-Louis Pasteur'
println "========================================="
nextflow.enable.dsl=2

include {RAW_METRICS_SINGLE_STRAND}     from './modules/cross-lab/metrics/main.nf'
include {RAW_METRICS_PAIRED_END}        from './modules/cross-lab/metrics/main.nf'
include {ALIGNED_METRICS}               from './modules/cross-lab/metrics/main.nf'
include {DEDUPED_METRICS}               from './modules/cross-lab/metrics/main.nf'
include {FASTP_PAIRED_END}                         from './modules/cross-lab/fastp/main.nf'
include {FASTP_SINGLE_END} from './modules/cross-lab/fastp/main.nf'
include {BWAMEM2}                       from './modules/cross-lab/bwamem2/main.nf'
include {BWAMEM2_INDEX}                 from './modules/cross-lab/bwamem2/main.nf'
include {DEDUPLICATE as DEDUP}          from './modules/cross-lab/deduplicate/main.nf'
include {MERGE_LANES}                   from './modules/cross-lab/merge_lanes/main.nf'
include {REPORT_COMPILATION}            from './modules/cross-lab/report_compilation/main.nf'
include {FINAL_REPORT}                  from './modules/cross-lab/final_report/main.nf'

include {SELECT_SNPS}                   from './modules/cross-lab/gatk_tools/main.nf'
include {SELECT_INDELS}                 from './modules/cross-lab/gatk_tools/main.nf'
include {FILTER_SNPS}                   from './modules/cross-lab/gatk_tools/main.nf'
include {FILTER_INDELS}                 from './modules/cross-lab/gatk_tools/main.nf'
include {MERGE_FILTERED_VARIANTS}       from './modules/cross-lab/gatk_tools/main.nf'
include {SELECT_PASSING}                from './modules/cross-lab/gatk_tools/main.nf'
include {BASE_RECALIBRATOR}             from './modules/cross-lab/gatk_tools/main.nf'
include {APPLY_BQSR}                    from './modules/cross-lab/gatk_tools/main.nf'
include {PREPARE_REFERENCE}             from './modules/cross-lab/gatk_tools/main.nf'
include {HAPLOTYPE_CALLER}              from './modules/cross-lab/gatk_tools/main.nf'
include {COVERAGE_MASK}                 from './modules/cross-lab/gatk_tools/main.nf'
include {CONSENSUS}                     from './modules/cross-lab/gatk_tools/main.nf'

include {PLOT_FULL_REFERENCE_UNIQUE}    from './modules/cross-lab/alt_cov_report/main.nf'

workflow {
    references_input = Channel
        .fromPath("${params.references}")
        .splitCsv(header: true, strip: true)
        .map { row ->
            def index_prefix = row.index_prefix_path ? row.index_prefix_path.trim() : "none"
            tuple(row.ref_name.trim(), file(row.ref_path.trim()), index_prefix)
        }


    // Creating the samples input channel
    if (params.single_end) {
        samples_input = Channel
            .fromPath("${params.indir}")
             .map { file ->
                def parts = file.simpleName.tokenize('_')
                def meta = [
                    sample_id:      parts[0],
                    read:    parts[1]
                ]
                tuple(sample_id, read)
            }
    } else {
        samples_input = Channel
            .fromFilePairs(
                "${params.indir}/*_R{1,2}_001.fastq.gz",
                flat: false
            )
            .map { sample_id, reads ->
                def clean_id = sample_id.replaceAll(/_S\d+_L\d+$/, '')
                tuple(clean_id, reads)
            }
    }

    samples_input.view()


   
    // Metrics
    if(params.single_end) {
        raw_metrics = RAW_METRICS_SINGLE_STRAND(samples_input)
    } else {
        raw_metrics = RAW_METRICS_PAIRED_END(samples_input)
    }

 
    

    // Prepare Reference
    PREPARE_REFERENCE(references_input)


    // Index references that don't have a pre-built index
    index = BWAMEM2_INDEX(references_input)


    // Join with .fai and .dict from PREPARE_REFERENCE
    references_full = index
        .join(PREPARE_REFERENCE.out.bundle)

   // Trimming
    if(params.single_end) {
        FASTP_SINGLE_END(samples_input, params.single_end)
        sample_x_ref = FASTP_SINGLE_END.out.fastp_trimmed
            .combine(references_full)
    }

    if(params.alignment.tool = "bwa-mem2") {
        BWAMEM2(sample_x_ref, params.single_end)
        aligned = BWAMEM2.out.aligned_sorted 
    }

    // ── Per SxR: Deduplicate ────────────────────────────────────
    DEDUP(aligned)

    // ── Per SxR: Variant Calling ────────────────────────────────
    HAPLOTYPE_CALLER(DEDUP.out.marked_bam)

    // ── Per SxR: Split → Filter → Merge ─────────────────────────
    SELECT_SNPS(HAPLOTYPE_CALLER.out.vcf)
    SELECT_INDELS(HAPLOTYPE_CALLER.out.vcf)

    FILTER_SNPS(SELECT_SNPS.out.snps)
    FILTER_INDELS(SELECT_INDELS.out.indels)

    // Join filtered SNPs + Indels by sxr_prefix
    // (NOT sample_id — one sample can map to multiple references!)
    merge_input = FILTER_SNPS.out.filtered_snps
        .map { sample_id, vcf, tbi, sxr_prefix, ref, ref_fai, ref_dict ->
            tuple(sxr_prefix, sample_id, vcf, tbi, ref, ref_fai, ref_dict)
        }
        .join(
            FILTER_INDELS.out.filtered_indels
                .map { sample_id, vcf, tbi, sxr_prefix, ref, ref_fai, ref_dict ->
                    tuple(sxr_prefix, vcf, tbi)
                },
            by: [0]  // join on sxr_prefix
        )
        .map { sxr_prefix, sample_id, snps_vcf, snps_tbi, ref, ref_fai, ref_dict,
               indels_vcf, indels_tbi ->
            tuple(sample_id, snps_vcf, snps_tbi, indels_vcf, indels_tbi,
                  sxr_prefix, ref, ref_fai, ref_dict)
        }

    MERGE_FILTERED_VARIANTS(merge_input)

    // ── Per SxR: Select PASS variants ───────────────────────────
    SELECT_PASSING(MERGE_FILTERED_VARIANTS.out.merged)

    // ── Per SxR: Coverage mask ──────────────────────────────────
    // Derive BAM channel for COVERAGE_MASK from DEDUP output
    coverage_bam = DEDUP.out.marked_bam
        .map { sample_id, bam, bai, ref_fasta, ref_fai, ref_dict, sxr_prefix ->
            tuple(sample_id, bam, bai, sxr_prefix)
        }

    COVERAGE_MASK(coverage_bam)

    // ── Per SxR: Consensus sequence ─────────────────────────────
    // Extract reference channel from DEDUP output, keyed by sxr_prefix
    ref_by_sxr = DEDUP.out.marked_bam
        .map { sample_id, bam, bai, ref_fasta, ref_fai, ref_dict, sxr_prefix ->
            tuple(sxr_prefix, ref_fasta, ref_fai)
        }

    // Join passing VCF + coverage mask + reference — all by sxr_prefix
    consensus_input = SELECT_PASSING.out.pass_vcf
        .map { sample_id, vcf, tbi, sxr_prefix ->
            tuple(sxr_prefix, sample_id, vcf, tbi)
        }
        .join(
            COVERAGE_MASK.out.mask
                .map { sample_id, mask_bed, sxr_prefix ->
                    tuple(sxr_prefix, mask_bed)
                },
            by: [0]  // join on sxr_prefix
        )
        .join(ref_by_sxr, by: [0])  // join on sxr_prefix
        .map { sxr_prefix, sample_id, vcf, tbi, mask_bed, ref_fasta, ref_fai ->
            tuple(sample_id, vcf, tbi, mask_bed, sxr_prefix, ref_fasta, ref_fai)
        }

    CONSENSUS(consensus_input)
    PLOT_FULL_REFERENCE_UNIQUE(DEDUP.out.marked_bam)
    // Concatenate all PDFs


}
