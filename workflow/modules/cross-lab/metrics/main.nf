process COMPILE_METRICS_SHEET {
    output:
    stdout

    script:
    """
    python3 $projectDir/modules/bin/metrics_table_gen.py
    """
}