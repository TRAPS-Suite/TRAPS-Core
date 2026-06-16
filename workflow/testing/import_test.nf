println "========================================="
println "  TRAPS | Parameter Testing              "
println "       v4.5.0   "
println "  Date: ${new Date()}                     "
println "========================================="
nextflow.enable.dsl=2

workflow {
 references_input = Channel
        .fromPath("${params.references}")
        .splitCsv(header: true, strip: true)
        .map { row ->
            def index_prefix = row.index_prefix_path ? row.index_prefix_path.trim() : "none"
            tuple(row.ref_name.trim(), file(row.ref_path.trim()), index_prefix)
        }

    if(params.single_end) {
    reads_ch = Channel
    .fromPath("${params.indir}/*.fastq.gz", checkIfExists: true)
    .map { file ->
        def sampleName = file.name.split('_')[0]
        [sampleName, file]
    }
    .view()
    } else {   
        reads_ch_in = Channel
        .fromFilePairs("${params.indir}/*_{R1,R2}_*.fastq.gz", checkIfExists: true)
        .map { sampleName, files ->
            [sampleName, files]
        }
        .view()
    
    reads_ch_in.view()
    }


}