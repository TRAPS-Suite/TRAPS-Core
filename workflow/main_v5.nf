println "========================================="
println "  TRAPS  "
println "  v6.0.0   "
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
include {BWAMEM2_INDEX; BWAMEM2} from "${tool_modules}/bwamem2/main.nf"
include {DEDUPLICATE} from "${tool_modules}/deduplicate/main.nf"
include {BCF_CALL_VARIANTS; BCF_FILTER_VARIANTS; CONSENSUS_SEQUENCE} from "${tool_modules}/bcftools_variant_calling/main.nf"
include {COMPILE_METRICS_SHEET} from "${metrics_modules}/main.nf"


workflow {
    // sample input channel def
    def sample_input_ch = Channel
        .fromPath("${params.indir}/*_S*_L00*_R1_001.fastq.gz")
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
    // indexing references
    BWAMEM2_INDEX(reference_input_ch)
    // Run FASTP
    FASTP(sample_input_ch)

    def sxr_channel = FASTP.out.reads.combine(reference_input_ch)
        .map {sample_meta, reads, ref_name_ext, ref_name_formatted, ref_path ->
            tuple(sample_meta, reads, ref_name_formatted, ref_path)
        }

    BWAMEM2(sxr_channel)
    
    DEDUPLICATE(BWAMEM2.out.aligned_sxr)

    BCF_CALL_VARIANTS(DEDUPLICATE.out.marked_sxr)

    BCF_FILTER_VARIANTS(BCF_CALL_VARIANTS.out.vcf)

    CONSENSUS_SEQUENCE(BCF_FILTER_VARIANTS.out.vcf)

    COMPILE_METRICS_SHEET() | view()


}