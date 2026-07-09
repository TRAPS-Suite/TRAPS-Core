println "========================================="
println "  TRAPS  "
println "  v6.4.0   "
println "  Date: ${new Date()}                     "
println "========================================="
println '"To know how to wonder and question is '
println 'the first step of the mind toward discovery."'
println '-Louis Pasteur'
println "========================================="
println "   Authored by Henry Sommer    "

nextflow.enable.dsl=2

// TOOL IMPORTS
tool_modules = "./modules/cross-lab/tools"
metrics_modules = "./modules/cross-lab/metrics"

include {FASTP} from "${tool_modules}/fastp/main.nf"
include {BWAMEM2_INDEX; BWAMEM2; CLEAN_REF} from "${tool_modules}/bwamem2/main.nf"
include {DEDUPLICATE} from "${tool_modules}/deduplicate/main.nf"
include {COMPILE_METRICS_SHEET} from "${metrics_modules}/main.nf"
include {BED_MASK; VARIANT_CALL; GENERATE_CONSENSUS} from "${tool_modules}/variant_calling/main.nf"
include {BUNDLE_RUN} from "${tool_modules}/bundling/main.nf"
include {SPLIT_TO_REFS} from "${tool_modules}/split_to_refs/main.nf"
include {CONSENSUS} from "${tool_modules}/ivar/main.nf"
workflow {
    // sample input channel def
    def sample_input_ch = Channel
        .fromPath("${params.indir}/*_S*_L001_R1_001.fastq.gz")
            .map { file1 ->
                def sampleId = file1.name.replaceAll(/_S\d+_L00.*/, '')
                def file2 = file1.parent.resolve(file1.name.replace('_R1_', '_R2_'))
                def meta = [id: sampleId]
                def reads = file2.exists() ? [file1, file2] : [file1]
                [meta, reads]
            }

    // reference input channel def
    def reference_input_ch = Channel
        .fromPath("${params.references}")
        .splitCsv(header: true)
        .map { row -> 
            def ref_name_normalized = row.ref_name_external.replaceAll(/\s+/, '_').toLowerCase()
            tuple( row.ref_name_external, ref_name_normalized, file(row.ref_path)) 
        }

    CLEAN_REF(reference_input_ch)
    // indexing references
    BWAMEM2_INDEX(CLEAN_REF.out.fasta.collect())
    // Run FASTP
    FASTP(sample_input_ch)

    BWAMEM2(FASTP.out.reads, BWAMEM2_INDEX.out.bm2_index_bundle)

    DEDUPLICATE(BWAMEM2.out.aligned)

    SPLIT_TO_REFS(DEDUPLICATE.out.marked_bam)
    
    CONSENSUS(SPLIT_TO_REFS.out.split_bams)

    //BUNDLE_RUN(DEDUPLICATE.out.marked_bam.collect())

}
