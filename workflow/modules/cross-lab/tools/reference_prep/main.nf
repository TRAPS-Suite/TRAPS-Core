process PREP_REF_FASTA {
    input:
    tuple val(ref_name), path(ref_path)

    output:
    tuple val("master"), path("master.fasta")

    script:
    """
    awk '1' ${ref_path} >> master.fasta
    """
}