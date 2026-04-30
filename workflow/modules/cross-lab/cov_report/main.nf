process PLOT_FULL_REFERENCE_UNIQUE {
    container "genomics_viz.sif"
    tag "${sxr_prefix}"
    publishDir "${params.outdir}/coverage_plots", mode: 'copy'

    input:
    tuple val(sample_id),
          path(marked_bam),
          path(marked_bam_bai),
          path(ref_path),
          path(ref_fai),
          path(ref_dict),
          val(sxr_prefix)

    output:
    path("${sxr_prefix}_coverage_map.pdf")

    script:
    """
    set -euo pipefail

    REF_NAME=\$(cut -f1 ${ref_fai} | head -n 1)
    REF_LEN=\$(cut -f2 ${ref_fai} | head -n 1)

    # 1. Generate BigWig ignoring duplicates
    bamCoverage -b ${marked_bam} -o ${sxr_prefix}.bw \
        --binSize 40 \
        --ignoreDuplicates

    # 2. Calculate average depth
    #    -a     = include ALL positions even if depth is 0
    #    -G 1024 = exclude reads flagged as duplicates
    #    Guard against division by zero in awk
    AVG_COV=\$(samtools depth \
        -a \
        -G 1024 \
        ${marked_bam} \
        | awk '{sum += \$3; n++} END {if (n > 0) printf "%.2f", sum/n; else print "0.00"}')

    echo "DEBUG: Average coverage for ${sxr_prefix} = \${AVG_COV}x"

    # 3. Verify
    if [ -z "\${AVG_COV}" ] || [ "\${AVG_COV}" = "-nan" ]; then
        echo "ERROR: Failed to calculate average coverage"
        echo "DEBUG: samtools depth output line count:"
        samtools depth -a -G 1024 ${marked_bam} | wc -l
        exit 1
    fi

    # 4. Create tracks.ini
    cat <<EOF > tracks.ini
[coverage]
file = ${sxr_prefix}.bw
title = Average Depth: \${AVG_COV}x
height = 6
color = #000000
type = line:1.0
min_value = 0
show_data_range = true
number_of_bins = 700

[x-axis]
where = bottom
EOF

    # 5. Generate the plot
    pyGenomeTracks \
        --tracks tracks.ini \
        --region \${REF_NAME}:1-\${REF_LEN} \
        --title "${sxr_prefix}" \
        --outFileName ${sxr_prefix}_coverage_map.pdf
    """
}