process FASTP {
    tag "$meta.id"
    publishDir "${params.outdir}/fastp", mode: 'copy'
    
    input:
    tuple val(meta), path(reads)
        
    output:
    tuple val(meta), path("*.trimmed.fastq.gz"), emit: reads
    path("*.json"), emit: report
    path(reads)
    
    script:
    def paired = reads.size() == 2
    def input_args = paired ? "-i ${reads[0]} -I ${reads[1]}" : "-i ${reads[0]}"
    def output_args = paired ? "-o ${meta.id}_R1.trimmed.fastq.gz -O ${meta.id}_R2.trimmed.fastq.gz" : "-o ${meta.id}.trimmed.fastq.gz"
    
    """
    fastp \\
        ${input_args} \\
        ${output_args} \\
        -j ${meta.id}_fastp.json \\
        -h ${meta.id}_fastp.html \\
        --thread ${task.cpus}
    """
}