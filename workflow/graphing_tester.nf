println "========================================="
println "Coverage Map 2"
println "  v4.5.0   "
println "  Date: ${new Date()}                     "
println "========================================="
println '"To know how to wonder and question is '
println 'the first step of the mind toward discovery."'
println '-Louis Pasteur'
println "========================================="
nextflow.enable.dsl=2

workflow {
    bams = Channel.fromPath("${params.outdir}/markduplicates/*.bam")

    // Branch the channel based on the 'type' property
    branches = bams.branch { item ->
    def type = item.name.take(3)
    homebrew: type == 'HB_'
    illumina: type == 'ILL'
    }

    //bams.view()

    branches.homebrew.view{"Sample: $it"}
}