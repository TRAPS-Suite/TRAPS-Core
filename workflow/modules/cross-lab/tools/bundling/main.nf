process BUNDLE_RUN {
    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path("*.traps"), emit: traps
    
    script:
    """
    OUTPUT_NF=\$(pwd)
    cd ${params.outdir}
    mkdir bundle_contents
    shopt -s extglob
    mv !(bundle_contents) bundle_contents/

    tar -czvf \$OUTPUT_NF/${params.run_name}.traps bundle_contents/

    """
}