process SPLIT_TO_REFS {
    tag "$meta.id"

    publishDir "${params.outdir}/split", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)
    path(refs_csv)

    output:
    tuple val(meta), path("*.sorted.bam"), path("*.sorted.bam.bai"),
    emit: split_bams

    script:
    """
    while IFS=',' read -r col1 col2 col3 || [ -n "$col1" ]; do
    # Skip the header row if your file has one
    if [ "$col1" = "ref_name_internal" ]; then continue; fi
    
    # Do something with the variables
    echo "Processing row: Column 1 is $col1, Column 2 is $col2"
    
    done < ${refs_csv}
    """

    // bam
    // sorted
    // indexed
}