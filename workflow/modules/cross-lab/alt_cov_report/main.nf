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
    def fig_width       = params.plot_fig_width       ?: 16
    def fig_height      = params.plot_fig_height      ?: 6
    def dpi             = params.plot_dpi             ?: 300
    def bin_size        = params.plot_bin_size        ?: 40
    def smooth_window   = params.plot_smooth_window   ?: 0
    def y_min           = params.plot_y_min           ?: 0
    def y_max           = params.plot_y_max           ?: 0
    def region_start    = params.plot_region_start    ?: 0
    def region_end      = params.plot_region_end      ?: 0
    def plot_style      = params.plot_style           ?: 'line'
    def line_color      = params.plot_line_color      ?: '#2b6ca3'
    def fill_color      = params.plot_fill_color      ?: '#a8cce0'
    def line_width      = params.plot_line_width      ?: 0.8
    def fill_alpha      = params.plot_fill_alpha      ?: 0.35
    def hlines          = params.plot_hlines          ?: ''
    def hline_colors    = params.plot_hline_colors    ?: 'red'
    def hline_styles    = params.plot_hline_styles    ?: 'dashed'
    def hline_labels    = params.plot_hline_labels    ?: ''
    def annotation_beds = params.plot_annotation_beds ?: ''
    def annotation_h    = params.plot_annotation_height ?: 0.6
    def custom_title    = params.plot_title           ?: ''
    def subtitle        = params.plot_subtitle        ?: ''
    def x_label         = params.plot_x_label         ?: 'Genomic Position'
    def y_label         = params.plot_y_label         ?: 'Read Depth'
    def font_size       = params.plot_font_size       ?: 12
    def title_pad       = params.plot_title_pad       ?: 45
    def avg_flag        = params.plot_show_avg_line != false ? '--show-avg-line' : '--no-avg-line'
    """
    set -euo pipefail

    # ── 1. Reference metadata ────────────────────────────────────────
    REF_NAME=\$(cut -f1 ${ref_fai} | head -n 1)
    REF_LEN=\$(cut -f2 ${ref_fai} | head -n 1)

    # ── 2. BigWig (duplicate-aware) ─────────────────────────────────
    bamCoverage -b ${marked_bam} -o ${sxr_prefix}.bw \
        --binSize ${bin_size} \
        --ignoreDuplicates

    # ── 3. Average depth ─────────────────────────────────────────────
    AVG_COV=\$(samtools depth -a -G 1024 ${marked_bam} \
        | awk '{sum += \$3; n++} END {if (n > 0) printf "%.2f", sum/n; else print "0.00"}')

    echo "DEBUG: Average coverage for ${sxr_prefix} = \${AVG_COV}x"

    if [ -z "\${AVG_COV}" ] || [ "\${AVG_COV}" = "-nan" ]; then
        echo "ERROR: Failed to calculate average coverage"
        samtools depth -a -G 1024 ${marked_bam} | wc -l
        exit 1
    fi

    # ── 4. Per-base depth table ──────────────────────────────────────
    samtools depth -a -G 1024 ${marked_bam} > ${sxr_prefix}_depth.tsv

    # ── 5. Plot ──────────────────────────────────────────────────────
    python3 ${projectDir}/modules/bin/plot_coverage.py \
        --depth-file      ${sxr_prefix}_depth.tsv \
        --output          ${sxr_prefix}_coverage_map.pdf \
        --avg-cov         \${AVG_COV} \
        --sample-prefix   '${sxr_prefix}' \
        --fig-width       ${fig_width} \
        --fig-height      ${fig_height} \
        --dpi             ${dpi} \
        --bin-size        ${bin_size} \
        --smooth-window   ${smooth_window} \
        --y-min           ${y_min} \
        --y-max           ${y_max} \
        --region-start    ${region_start} \
        --region-end      ${region_end} \
        --plot-style      ${plot_style} \
        --line-color      '${line_color}' \
        --fill-color      '${fill_color}' \
        --line-width      ${line_width} \
        --fill-alpha      ${fill_alpha} \
        --hlines          '${hlines}' \
        --hline-colors    '${hline_colors}' \
        --hline-styles    '${hline_styles}' \
        --hline-labels    '${hline_labels}' \
        --annotation-beds '${annotation_beds}' \
        --annotation-height ${annotation_h} \
        --title           '${custom_title}' \
        --subtitle        '${subtitle}' \
        --x-label         '${x_label}' \
        --y-label         '${y_label}' \
        --font-size       ${font_size} \
        --title-pad       ${title_pad} \
        ${avg_flag}
    """
}