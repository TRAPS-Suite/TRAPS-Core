println "========================================="
println "  TRAPS    "
println "  v0.3.1   "
println "  Date: ${new Date()}                     "
println "========================================="

nextflow.enable.dsl=2

include { FASTP }                from './modules/cross-lab/fastp/main.nf'
include { BWAMEM2 as ALIGN}              from './modules/cross-lab/bwamem2/main.nf'
include { DEDUPLICATE as DEDUP}          from './modules/cross-lab/deduplicate/main.nf'
include { WORKFLOW_METRICS as PRE_FASTP}      from './modules/cross-lab/workflow_metrics/main.nf'
include { WORKFLOW_METRICS as POST_FASTP}      from './modules/cross-lab/workflow_metrics/main.nf'
include { WORKFLOW_METRICS as POST_DEDUPING}      from './modules/cross-lab/workflow_metrics/main.nf'
include { MERGE_LANES } from './modules/cross-lab/merge_lanes/main.nf'
include { REPORT_COMPILATION } from './modules/cross-lab/report_compilation/main.nf'
include { FINAL_REPORT } from './modules/cross-lab/final_report/main.nf'
params.laneread = "/work/crosslab/hsommer/testing_data/tdata/*/*_R{1,2}.fastq.gz"


workflow {
    // Defining input channel
    // Format: abcd_Lx_Ry.fastq.gz
    Channel
    .fromPath(params.laneread)
    .map { file ->
        def m = (file.baseName =~ /(.*)_L\d+_(R[12])/)
        def sample = m[0][1]
        def read   = m[0][2]
        tuple(sample, read, file)
    }
    .groupTuple(by:0)
    .map { sample, reads, files ->
        def r1 = []
        def r2 = []
        reads.eachWithIndex { r, i ->
            if( r == 'R1' )
                r1 << files[i]
            else
                r2 << files[i]
        }
        tuple(sample, r1.sort(), r2.sort())
    }
    .set{lane_pairs_ch}
    

    
    // Merging Lanes
    merged_ch = MERGE_LANES(lane_pairs_ch)
    //merged_ch.view()

    // Workflow Metrics (Pre FASTP)
    raw_metrics_ch = lane_pairs_ch.map { sample_id, r1, r2 ->
    tuple(sample_id, r1, "raw")
    }
    raw_metrics_results = PRE_FASTP(raw_metrics_ch)

    // Trimming Reads
    trimmed_ch = FASTP(lane_pairs_ch)

    // Workflow Metrics (Post FASTP)
    trimmed_metrics_ch = trimmed_ch.map { sample_id, r1, r2, json, html ->
    tuple(sample_id, r1, "trimmed")
    }
    trimmed_metrics_results = POST_FASTP(trimmed_metrics_ch)

    // Aligning Reads
    aligned_ch = ALIGN(trimmed_ch)

    // Deduplicating Reads
    dedup_ch = DEDUP(aligned_ch)

    

    // Workflow Metrics (Post deduping, for each reference)
    dedup_metrics_ch = dedup_ch.map { sample_id, bam, index -> tuple(sample_id, bam, "metrics") }
    workflow_metrics_results = POST_DEDUPING(dedup_metrics_ch)


    //raw_metrics_results.view()
    //trimmed_metrics_results.view()
    //workflow_metrics_results.view()

    metrics_join1 = raw_metrics_results.join(trimmed_metrics_results)
    pre_input_channel = metrics_join1.join(workflow_metrics_results)
    pre_input_channel1 = pre_input_channel.join(dedup_ch)


    // Combine the two single-element channels into a new channel
    aligned_ch_in = aligned_ch.map { sample_id, bam, index -> tuple(sample_id, index)}

    //aligned_ch_in.view()

    input_channel = pre_input_channel1.join(aligned_ch_in)

    //input_channel.view()

    csv_list = REPORT_COMPILATION(input_channel)
    
    FINAL_REPORT(csv_list.collect())
}
