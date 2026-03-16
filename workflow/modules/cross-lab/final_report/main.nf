    process FINAL_REPORT {


    input:
    path report_list

    output:
    path "final_report.csv"

    script:
    """
    awk 'NR == 1 || FNR > 1' ${report_list} > final_report.csv
    """
}