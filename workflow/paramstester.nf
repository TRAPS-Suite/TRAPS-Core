println "========================================="
println "  TRAPS | Parameter Testing  "
println "  v4.5.0   "
println "  Date: ${new Date()}                     "
println "========================================="
nextflow.enable.dsl=2

workflow {
    println($params.indir)
}