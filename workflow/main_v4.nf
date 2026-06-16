println "========================================="
println "  TRAPS  "
println "  v6.0   "
println "  Date: ${new Date()}                     "
println "========================================="
println '"To know how to wonder and question is '
println 'the first step of the mind toward discovery."'
println '-Louis Pasteur'
println "========================================="
println "   Authored by Henry Sommer    "

nextflow.enable.dsl=2

include {RAW_METRICS}     from './modules/cross-lab/metrics/main.nf'
include {ALIGNED_METRICS}               from './modules/cross-lab/metrics/main.nf'
include {DEDUPED_METRICS}               from './modules/cross-lab/metrics/main.nf'

include {SPLIT_TO_REFS} from './modules/cross-lab/tools/split_to_refs/main.nf'

include{PREP_REF_FASTA} from './modules/cross-lab/tools/reference_prep/main.nf'

include {FASTP}                         from './modules/cross-lab/tools/fastp/main.nf'
include {BWAMEM2}                       from './modules/cross-lab/tools/bwamem2/main.nf'
include {BWAMEM2_INDEX}                 from './modules/cross-lab/tools/bwamem2/main.nf'
include {CONCATENATE_REFERENCES} from './modules/cross-lab/tools/bwamem2/main.nf'

include {DEDUPLICATE}          from './modules/cross-lab/tools/deduplicate/main.nf'
include {MERGE_LANES}                   from './modules/cross-lab/tools/merge_lanes/main.nf'

include {SELECT_SNPS}                   from './modules/cross-lab/tools/gatk_tools/main.nf'
include {SELECT_INDELS}                 from './modules/cross-lab/tools/gatk_tools/main.nf'
include {FILTER_SNPS}                   from './modules/cross-lab/tools/gatk_tools/main.nf'
include {FILTER_INDELS}                 from './modules/cross-lab/tools/gatk_tools/main.nf'
include {MERGE_FILTERED_VARIANTS}       from './modules/cross-lab/tools/gatk_tools/main.nf'
include {SELECT_PASSING}                from './modules/cross-lab/tools/gatk_tools/main.nf'
include {BASE_RECALIBRATOR}             from './modules/cross-lab/tools/gatk_tools/main.nf'
include {APPLY_BQSR}                    from './modules/cross-lab/tools/gatk_tools/main.nf'
include {PREPARE_REFERENCE}             from './modules/cross-lab/tools/gatk_tools/main.nf'
include {HAPLOTYPE_CALLER}              from './modules/cross-lab/tools/gatk_tools/main.nf'
include {COVERAGE_MASK}                 from './modules/cross-lab/tools/gatk_tools/main.nf'
include {CONSENSUS}                     from './modules/cross-lab/tools/gatk_tools/main.nf'

include {FULL_RUN_METRIC_TABLE_GEN} from './modules/cross-lab/reporting/full_run_metric_table_gen/main.nf'

workflow {
    // Sample triage
    samples_ch = Channel
        .fromPath("${params.indir}/*_S*_L00*_R1_001.fastq.gz")
        .map { file1 ->
            def sampleId = file1.name.replaceAll(/_S1_L00.*/, '')
            def file2 = file1.parent.resolve(file1.name.replace('_R1_', '_R2_'))
            def meta = [id: sampleId]
            def reads = file2.exists() ? [file1, file2] : [file1]
            [meta, reads]
        }
    // References Triage
    Channel
    .fromPath("${params.references}")
    .splitCsv(header: true)
    .map { row ->
        [row.ref_name_internal, row.ref_name_external, file(row.ref_path)]
    }
    .set { unindexed_references_ch }


    // Create BWA-MEM2 Index 
    concatenated_ref = unindexed_references_ch
        .map { ref_name_internal, ref_name_external, ref_path -> ref_path }
        .collect()
        .set { all_refs }
    
    CONCATENATE_REFERENCES(all_refs)
    BWAMEM2_INDEX(CONCATENATE_REFERENCES.out.fasta)


    // Start of main
    // Trimming
    FASTP(samples_ch)
    FASTP.out.reads.view()

    // Alignment
    BWAMEM2(FASTP.out.reads)

    DEDUPLICATE(BWAMEM2.out.bam)

    SPLIT_TO_REFS(DEDUPLICATE.out.marked_bam, params.references)


    HAPLOTYPE_CALLER(SPLIT_TO_REFS.out.split_bams)

    SELECT_SNPS(HAPLOTYPE_CALLER.out.vcf)
    SELECT_INDELS(HAPLOTYPE_CALLER.out.vcf)

    FILTER_SNPS(SELECT_SNPS.out.snps)
    FILTER_INDELS(SELECT_INDELS.out.indels)

    MERGE_FILTERED_VARIANTS(FILTER_SNPS.out.filtered_snps, FILTER_INDELS.out.filtered_indels)
    SELECT_PASSING(MERGE_FILTERED_VARIANTS.out.merged)

    //COVERAGE_MASK(split_bams_with_refs_ch)


    //CONSENSUS(SELECT_PASSING.out.pass_vcf, COVERAGE_MASK.out.mask, split_bams_with_refs_ch)

}