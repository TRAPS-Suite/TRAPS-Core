    process FINAL_REPORT {

    publishDir "${params.outdir}/report", mode: 'copy'

    input:
    path report_list

    output:
    path "final_report.csv"

    script:
    """
    awk 'NR == 1 || FNR > 1' ${report_list} > final_report.csv
    """
}