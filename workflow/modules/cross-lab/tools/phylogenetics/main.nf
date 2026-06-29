process ADD_TO_ALIGNMENT {
    tag "$meta"
    publishDir "${params.outdir}/phylogenetics", mode: 'copy'
    
    input:
    tuple val(meta), path(fasta), val(ref_name)

    output:
    tuple val(meta), path("*.fasta"), emit: running
    
    script:
    """
    if [[ "${ref_name}" == "west_nile_virus" ]]; then
        if [ -f "${params.outdir}/phylogenetics/running_alignment.fasta" ]; then
            mafft --add ${fasta} ${params.outdir}/phylogenetics/running_alignment.fasta > running_alignment.fasta
        else
            mafft --add ${fasta} ${workflow.projectDir}/../templates/west_nile_virus.fasta > running_alignment.fasta
        fi
    else
        touch pass.fasta
    fi
    """
}

process RECOMPILE_TREE {
    input:
    tuple val(meta), path(fasta)

    script:
    """
    iqtree2 -s ${params.outdir}/phylogenetics/running_alignment.fasta -m TIM+F+I -bb 1000 -nt AUTO
    """
}