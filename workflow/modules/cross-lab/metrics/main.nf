process COMPILE_METRICS_SHEET {
    input:
    tuple val(meta), path(bam), path(bai), val(ref_name), path(ref_path)

    output:
    stdout

    script:
    """
    python3 $projectDir/modules/bin/metrics_table_gen.py $params.outdir $params.references
    """
}