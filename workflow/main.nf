println "========================================="
println "  TRAP-Seq    "
println "  v1.0.0   "
println "  Date: ${new Date()}                     "
println "========================================="

nextflow.enable.dsl=2

include { FASTP }                from './modules/cross-lab/fastp/main.nf'
include { BWAMEM2 as ALIGN}              from './modules/cross-lab/bwamem2/main.nf'
include { DEDUPLICATE as DEDUP}          from './modules/cross-lab/deduplicate/main.nf'
include { MERGE_LANES } from './modules/cross-lab/merge_lanes/main.nf'
include { REPORT_COMPILATION } from './modules/cross-lab/report_compilation/main.nf'
include { FINAL_REPORT } from './modules/cross-lab/final_report/main.nf'
include { RAW_METRICS } from './modules/cross-lab/raw_metrics/main.nf'
include { TRIMMED_METRICS } from './modules/cross-lab/trimmed_metrics/main.nf'
include { DEDUPED_METRICS } from './modules/cross-lab/deduped_metrics/main.nf'
include { ALIGNED_METRICS } from './modules/cross-lab/aligned_metrics/main.nf'
include {BASE_RECALIBRATOR} from './modules/cross-lab/gatk_tools/main.nf'
include{APPLY_BQSR} from './modules/cross-lab/gatk_tools/main.nf'
include{PREPARE_REFERENCE} from './modules/cross-lab/gatk_tools/main.nf'
include{HAPLOTYPE_CALLER} from './modules/cross-lab/gatk_tools/main.nf'

// /work/crosslab/hsommer/testing_data/tdata
params.laneread = "${params.indir}/*_R{1,2}.fastq.gz"
workflow {

    refs_ch = Channel
        .fromPath(params.refs, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            tuple(
                row.ref_id,
                file(row.ref_fasta, checkIfExists: true)
            )
        }

    PREPARE_REFERENCE(refs_ch)

    samples_ch = Channel
        .fromPath(params.laneread)
        .map { file ->
            def m = (file.baseName =~ /(.*)_(R[12])/)
            def sample = m[0][1]
            def read   = m[0][2]
            tuple(sample, read, file)
        }
        .groupTuple(by:0)
        .map { sample, reads, files ->
            def r1 = []
            def r2 = []
            reads.eachWithIndex { r, i ->
                if (r == 'R1')
                    r1 << files[i]
                else
                    r2 << files[i]
            }
            tuple(sample, r1.sort(), r2.sort())
        }

    calling_input = samples_ch
        .combine(PREPARE_REFERENCE.out.bundle, by: 0)
        .map{ref_id,sample_id,bam,bai,fasta,fai,dict -->
            tuple(sample_id, ref_id, bam, bai, fasta, fai, dict)
        }

    bams_for_calling = calling_input

    


    // Getting raw metrics
    raw_metrics_results = RAW_METRICS(samples_ch)

    // Trimming Reads & Getting Metrics
    trimmed_ch = FASTP(lane_pairs_ch)
    trimmed_metrics_results = TRIMMED_METRICS(trimmed_ch)

    //trimmed_ch.view()

    // Aligning Reads & Getting Metrics
    aligned_ch = ALIGN(trimmed_ch)
    //aligned_ch.view()
    ALIGNED_METRICS(aligned_ch)

    // Deduplicating Reads & Getting Metrics
    dedup_ch = DEDUP(aligned_ch)

    // Workflow Metrics (Post deduping, for each reference)
    DEDUPED_METRICS(dedup_ch)

    //csv_list = REPORT_COMPILATION()

    // Wait until all CSVs are exported and assemble into a final report with the Python script
    //FINAL_REPORT(csv_list.collect())


    //dedup_ch.view()

    



    // 2. Define empty lists (as channels or values)
    //empty_list1 = []
    //empty_list2 = []

    // 3. Create new channel by mixing all components
    //dedup_ch.view()

}