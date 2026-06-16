println "========================================="
println "  TRAPS  "
println "  v5.2.0   "
println "  Date: ${new Date()}                     "
println "========================================="
println '"To know how to wonder and question is '
println 'the first step of the mind toward discovery."'
println '-Louis Pasteur'
println "========================================="
println "   Authored by Henry Sommer    "

nextflow.enable.dsl=2

include {RAW_METRICS}     from './modules/cross-lab/metrics/main.nf'
include {ALIGNED_METRICS_PAIRED_END}               from './modules/cross-lab/metrics/main.nf'
include {ALIGNED_METRICS_SINGLE_END} from './modules/cross-lab/metrics/main.nf'
include {DEDUPED_METRICS_SINGLE_END}               from './modules/cross-lab/metrics/main.nf'

include{PREP_REF_FASTA} from './modules/cross-lab/tools/reference_prep/main.nf'

include {FASTP_PAIRED_END}                         from './modules/cross-lab/tools/fastp/main.nf'
include {FASTP_SINGLE_END} from './modules/cross-lab/tools/fastp/main.nf'
include {BWAMEM2}                       from './modules/cross-lab/tools/bwamem2/main.nf'
include {BWAMEM2_INDEX}                 from './modules/cross-lab/tools/bwamem2/main.nf'
include {DEDUPLICATE as DEDUP}          from './modules/cross-lab/tools/deduplicate/main.nf'
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
    references_input = Channel
        .fromPath("${params.references}")
        .splitCsv(header: true, strip: true)
        .map { row ->
            def index_prefix = row.index_prefix_path ? row.index_prefix_path.trim() : "none"
            tuple(row.ref_name.trim(), file(row.ref_path.trim()))
        }

    reads_ch_in = Channel
    .fromPath("${params.indir}/*_R{1,2}_001.fastq.gz", checkIfExists: true)
    .map { file ->

        def sample_id = file.name.tokenize('_')[0]

        tuple(sample_id, file)
    }
    .groupTuple()
    .map { sample_id, files ->

        files = files.sort { it.name }

        def meta = [ sample_id: sample_id ]

        def outs = []

        tuple(meta, files)
    }
   
    raw_metrics = RAW_METRICS(reads_ch_in)

 
    

    // Prepare Reference
    PREPARE_REFERENCE(references_input)


    // Index references that don't have a pre-built index
    master_fasta = PREP_REF_FASTA(references_input)

    index = BWAMEM2_INDEX(master_fasta)


    // Join with .fai and .dict from PREPARE_REFERENCE
    references_full = index
        .join(PREPARE_REFERENCE.out.bundle)

 // Trimming
FASTP_SINGLE_END(reads_ch_in, params.single_end)
sample_trimmed = FASTP_SINGLE_END.out.fastp_trimmed

// Alignment - single reference, no combining with multiple refs
if(params.alignment.tool == "bwa-mem2") {
    BWAMEM2(sample_trimmed, params.single_end)
    aligned = BWAMEM2.out.aligned_sorted
    if(params.single_end) {
        ALIGNED_METRICS_SINGLE_END(aligned)
    }
}

// ── Per Sample: Deduplicate ────────────────────────────────────
DEDUP(aligned)

DEDUPED_METRICS_SINGLE_END(DEDUP.out.marked_bam)

// ── Per Sample: Variant Calling ────────────────────────────
HAPLOTYPE_CALLER(DEDUP.out.marked_bam)

// ── Per Sample: Split → Filter → Merge ─────────────────────────
SELECT_SNPS(HAPLOTYPE_CALLER.out.vcf)
SELECT_INDELS(HAPLOTYPE_CALLER.out.vcf)

FILTER_SNPS(SELECT_SNPS.out.snps)
FILTER_INDELS(SELECT_INDELS.out.indels)

// Join filtered SNPs + Indels by sample_id
merge_input = FILTER_SNPS.out.filtered_snps
    .map { sample_id, vcf, tbi, ref, ref_fai, ref_dict ->
        tuple(sample_id, vcf, tbi, ref, ref_fai, ref_dict)
    }
    .join(
        FILTER_INDELS.out.filtered_indels
            .map { sample_id, vcf, tbi, ref, ref_fai, ref_dict ->
                tuple(sample_id, vcf, tbi)
            },
        by: [0]  // join on sample_id
    )
    .map { sample_id, snps_vcf, snps_tbi, ref, ref_fai, ref_dict,
           indels_vcf, indels_tbi ->
        tuple(sample_id, snps_vcf, snps_tbi, indels_vcf, indels_tbi,
              ref, ref_fai, ref_dict)
    }

MERGE_FILTERED_VARIANTS(merge_input)

// ── Per Sample: Select PASS variants ───────────────────────────
SELECT_PASSING(MERGE_FILTERED_VARIANTS.out.merged)

// ── Per Sample: Coverage mask ──────────────────────────────────
coverage_bam = DEDUP.out.marked_bam
    .map { sample_id, bam, bai, ref_fasta, ref_fai, ref_dict ->
        tuple(sample_id, bam, bai)
    }

COVERAGE_MASK(coverage_bam)

// ── Per Sample: Consensus sequence ─────────────────────────────
// Extract reference channel from DEDUP output
ref_channel = DEDUP.out.marked_bam
    .map { sample_id, bam, bai, ref_fasta, ref_fai, ref_dict ->
        tuple(ref_fasta, ref_fai)
    }
    .first()  // get reference once (same for all samples)

// Join passing VCF + coverage mask + reference
consensus_input = SELECT_PASSING.out.pass_vcf
    .map { sample_id, vcf, tbi ->
        tuple(sample_id, vcf, tbi)
    }
    .join(
        COVERAGE_MASK.out.mask
            .map { sample_id, mask_bed ->
                tuple(sample_id, mask_bed)
            },
        by: [0]  // join on sample_id
    )
    .combine(ref_channel)  // add the single reference to all samples
    .map { sample_id, vcf, tbi, mask_bed, ref_fasta, ref_fai ->
        tuple(sample_id, vcf, tbi, mask_bed, ref_fasta, ref_fai)
    }

CONSENSUS(consensus_input)


}

// Culex tarsalis