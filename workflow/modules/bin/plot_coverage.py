#!/usr/bin/env python3
"""
Coverage map plotter with full customization.
Called by the PLOT_FULL_REFERENCE_UNIQUE Nextflow process.
All parameters are passed via argparse.
"""

import argparse
import csv
import os
import sys

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib import gridspec


# ─── Helpers ──────────────────────────────────────────────────────────────────

def parse_csv_param(s):
    """Split a comma-separated string, stripping whitespace."""
    if not s:
        return []
    return [x.strip() for x in s.split(",") if x.strip()]


def rolling_mean(arr, w):
    """Simple rolling average; returns original array if window < 2."""
    if w < 2 or len(arr) < w:
        return arr
    kernel = np.ones(w) / w
    return np.convolve(arr, kernel, mode="same")


def parse_bed(path):
    """Read a BED file and return list of (chrom, start, end, name, color)."""
    regions = []
    with open(path) as fh:
        for line in fh:
            if line.startswith("#") or line.strip() == "":
                continue
            cols = line.strip().split("\t")
            chrom = cols[0]
            start = int(cols[1])
            end = int(cols[2])
            name = cols[3] if len(cols) > 3 else ""
            color = cols[8] if len(cols) > 8 else "#4a86c8"
            regions.append((chrom, start, end, name, color))
    return regions


# ─── Core drawing ─────────────────────────────────────────────────────────────

def draw_coverage(ax, positions, depths, args, avg_cov):
    """Render coverage data on a single Axes."""

    # Optional region trim
    if args.region_start > 0 or args.region_end > 0:
        rs = args.region_start if args.region_start > 0 else positions.min()
        re = args.region_end if args.region_end > 0 else positions.max()
        mask = (positions >= rs) & (positions <= re)
        positions = positions[mask]
        depths = depths[mask]

    if len(positions) == 0:
        ax.text(0.5, 0.5, "[no data in region]", transform=ax.transAxes,
                ha="center", va="center", fontsize=args.font_size)
        return

    # Binning
    if args.bin_size > 1 and len(positions) > args.bin_size:
        n_bins = max(1, len(positions) // args.bin_size)
        idx = np.array_split(np.arange(len(positions)), n_bins)
        positions = np.array([positions[i].mean() for i in idx])
        depths = np.array([depths[i].mean() for i in idx])

    # Smoothing
    if args.smooth_window > 1:
        depths = rolling_mean(depths, args.smooth_window)

    # Plot style
    if args.plot_style == "fill":
        ax.fill_between(positions, 0, depths, color=args.fill_color, alpha=args.fill_alpha)
        ax.plot(positions, depths, color=args.line_color, linewidth=args.line_width)
    elif args.plot_style == "bar":
        bar_w = (positions[-1] - positions[0]) / len(positions)
        ax.bar(positions, depths, width=bar_w,
               color=args.fill_color, edgecolor=args.line_color, linewidth=0.1)
    elif args.plot_style == "heatmap":
        extent = [positions.min(), positions.max(), 0, 1]
        ax.imshow(depths.reshape(1, -1), aspect="auto", extent=extent,
                  cmap="viridis", interpolation="bilinear")
        ax.set_yticks([])
    else:  # line (default)
        ax.plot(positions, depths, color=args.line_color, linewidth=args.line_width)

    # Average depth line
    if args.show_avg_line and args.plot_style != "heatmap":
        ax.axhline(y=avg_cov, color="red", linewidth=0.7, linestyle="dashed",
                   label=f"Mean: {avg_cov:.2f}x")

    # Horizontal threshold lines
    hlines = parse_csv_param(args.hlines)
    hline_colors = parse_csv_param(args.hline_colors)
    hline_styles = parse_csv_param(args.hline_styles)
    hline_labels = parse_csv_param(args.hline_labels)
    for i, h in enumerate(hlines):
        hval = float(h)
        hc = hline_colors[i] if i < len(hline_colors) else "grey"
        hs = hline_styles[i] if i < len(hline_styles) else "dashed"
        hl = hline_labels[i] if i < len(hline_labels) else f"{hval}x"
        ax.axhline(y=hval, color=hc, linestyle=hs, linewidth=0.8, label=hl)

    # Legend
    handles, labels = ax.get_legend_handles_labels()
    if handles:
        ax.legend(fontsize=args.font_size - 2, loc="upper right")

    # Y-axis limits
    if args.plot_style != "heatmap":
        ax.set_ylim(bottom=args.y_min)
        if args.y_max > 0:
            ax.set_ylim(top=args.y_max)

    # Axis labels
    ax.set_xlabel(args.x_label, fontsize=args.font_size)
    if args.plot_style != "heatmap":
        ax.set_ylabel(args.y_label, fontsize=args.font_size)
    ax.tick_params(labelsize=args.font_size - 1)
    ax.ticklabel_format(axis="x", style="plain", useOffset=False)


def draw_annotations(ax, annotation_beds, font_size, chrom_filter=None):
    """Draw BED-based annotation rectangles on a thin Axes row."""
    for bed_path in annotation_beds:
        if not os.path.isfile(bed_path):
            print(f"WARNING: annotation BED not found: {bed_path}", file=sys.stderr)
            continue
        regions = parse_bed(bed_path)
        y_pos = 0.5
        for chrom, s, e, name, color in regions:
            if chrom_filter and chrom != chrom_filter:
                continue
            ax.add_patch(mpatches.FancyBboxPatch(
                (s, y_pos - 0.3), e - s, 0.6,
                boxstyle="round,pad=0.01", facecolor=color,
                edgecolor="black", linewidth=0.5))
            mid = (s + e) / 2
            ax.text(mid, y_pos, name, ha="center", va="center",
                    fontsize=font_size - 3)
    ax.set_ylim(0, 1)
    ax.set_yticks([])
    ax.set_xlabel("")


# ─── Data loading ─────────────────────────────────────────────────────────────

def load_depth(path):
    """
    Read a samtools-depth TSV (single reference per BAM).
    Returns: positions array, depths array, reference name
    """
    positions = []
    depths = []
    ref_name = None

    with open(path) as fh:
        reader = csv.reader(fh, delimiter="\t")
        for row in reader:
            if ref_name is None:
                ref_name = row[0]
            positions.append(int(row[1]))
            depths.append(int(row[2]))

    return np.array(positions), np.array(depths), ref_name


# ─── Main ─────────────────────────────────────────────────────────────────────

def build_parser():
    p = argparse.ArgumentParser(
        description="Coverage map plotter for a single-reference BAM")

    # ── Required ──────────────────────────────────────────────────────
    p.add_argument("--depth-file", required=True,
                   help="samtools depth TSV (one reference)")
    p.add_argument("--output", required=True,
                   help="Output PDF path")
    p.add_argument("--avg-cov", required=True, type=float,
                   help="Pre-calculated average coverage")
    p.add_argument("--sample-prefix", required=True,
                   help="Sample/run prefix used in default title")

    # ── Figure layout ─────────────────────────────────────────────────
    p.add_argument("--fig-width", type=float, default=16,
                   help="Figure width in inches (default: 16)")
    p.add_argument("--fig-height", type=float, default=6,
                   help="Figure height in inches (default: 6)")
    p.add_argument("--dpi", type=int, default=300,
                   help="Output resolution (default: 300)")

    # ── Binning / smoothing ───────────────────────────────────────────
    p.add_argument("--bin-size", type=int, default=40,
                   help="Bases per bin for averaging (default: 40)")
    p.add_argument("--smooth-window", type=int, default=0,
                   help="Rolling-mean window size, 0=off (default: 0)")

    # ── Axis limits ───────────────────────────────────────────────────
    p.add_argument("--y-min", type=float, default=0,
                   help="Y-axis minimum (default: 0)")
    p.add_argument("--y-max", type=float, default=0,
                   help="Y-axis maximum, 0=auto (default: 0)")

    # ── Region of interest ────────────────────────────────────────────
    p.add_argument("--region-start", type=int, default=0,
                   help="Crop to this start position, 0=beginning (default: 0)")
    p.add_argument("--region-end", type=int, default=0,
                   help="Crop to this end position, 0=end of ref (default: 0)")

    # ── Visual style ──────────────────────────────────────────────────
    p.add_argument("--plot-style", default="line",
                   choices=["line", "fill", "bar", "heatmap"],
                   help="Plot type (default: line)")
    p.add_argument("--line-color", default="#2b6ca3",
                   help="Line / edge color (default: #2b6ca3)")
    p.add_argument("--fill-color", default="#a8cce0",
                   help="Fill / bar color (default: #a8cce0)")
    p.add_argument("--line-width", type=float, default=0.8,
                   help="Line weight (default: 0.8)")
    p.add_argument("--fill-alpha", type=float, default=0.35,
                   help="Fill transparency (default: 0.35)")

    # ── Threshold / reference lines ───────────────────────────────────
    p.add_argument("--hlines", default="",
                   help="Comma-separated depth thresholds, e.g. '30,100'")
    p.add_argument("--hline-colors", default="red",
                   help="Comma-separated colors for threshold lines")
    p.add_argument("--hline-styles", default="dashed",
                   help="Comma-separated styles: solid,dashed,dotted")
    p.add_argument("--hline-labels", default="",
                   help="Comma-separated labels for threshold lines")
    p.add_argument("--show-avg-line", action="store_true", default=True,
                   help="Draw mean-depth reference line (default: on)")
    p.add_argument("--no-avg-line", action="store_false", dest="show_avg_line",
                   help="Hide mean-depth reference line")

    # ── Annotation tracks ─────────────────────────────────────────────
    p.add_argument("--annotation-beds", default="",
                   help="Comma-separated BED file paths for feature tracks")
    p.add_argument("--annotation-height", type=float, default=0.6,
                   help="Height of annotation row in inches (default: 0.6)")

    # ── Title & labels ────────────────────────────────────────────────
    p.add_argument("--title", default="",
                   help="Override the auto-generated title")
    p.add_argument("--subtitle", default="",
                   help="Smaller line displayed below the title")
    p.add_argument("--x-label", default="Genomic Position",
                   help="X-axis label (default: 'Genomic Position')")
    p.add_argument("--y-label", default="Read Depth",
                   help="Y-axis label (default: 'Read Depth')")
    p.add_argument("--font-size", type=int, default=12,
                   help="Base font size (default: 12)")
    p.add_argument("--title-pad", type=float, default=45,
                   help="Space above title in points (default: 45)")

    return p


def main():
    args = build_parser().parse_args()

    # ── Load data (single reference) ─────────────────────────────────
    positions, depths, ref_name = load_depth(args.depth_file)
    avg_cov = args.avg_cov

    if len(positions) == 0:
        print("ERROR: No depth data found.", file=sys.stderr)
        sys.exit(1)

    print(f"Reference: {ref_name}  |  Length: {positions.max()}  |  "
          f"Avg depth: {avg_cov}x", file=sys.stderr)

    # ── Annotation setup ──────────────────────────────────────────────
    annotation_beds = parse_csv_param(args.annotation_beds)
    has_annotations = bool(annotation_beds)

    # ── Figure geometry ───────────────────────────────────────────────
    height_ratios = [args.fig_height]
    if has_annotations:
        height_ratios.append(args.annotation_height)

    fig = plt.figure(figsize=(args.fig_width, sum(height_ratios)), dpi=args.dpi)
    gs = gridspec.GridSpec(len(height_ratios), 1,
                           height_ratios=height_ratios, hspace=0.25)

    # ── Coverage panel ────────────────────────────────────────────────
    ax = fig.add_subplot(gs[0])
    draw_coverage(ax, positions, depths, args, avg_cov)

    # ── Title construction ────────────────────────────────────────────
    sxr = args.sample_prefix
    title_sliced = sxr.split("-")

    if args.title:
        main_title = args.title
    else:
        main_title = title_sliced[0]

    if len(title_sliced) >= 2:
        pathogen_line = f"Pathogen: {title_sliced[1]}"
    else:
        pathogen_line = ""

    subtitle_text = args.subtitle if args.subtitle else f"Average Depth: {avg_cov}x"

    # Line 1: sample name — bold, largest
    ax.set_title(main_title, fontsize=args.font_size + 2,
                 fontweight="bold", pad=args.title_pad)

    # Line 2: pathogen — medium, semibold
    if pathogen_line:
        ax.text(0.5, 1.08, pathogen_line,
                transform=ax.transAxes,
                ha="center", va="bottom",
                fontsize=args.font_size,
                fontweight="semibold",
                color="#333333")

    # Line 3: average depth — smallest, grey
    if subtitle_text:
        ax.text(0.5, 1.01, subtitle_text,
                transform=ax.transAxes,
                ha="center", va="bottom",
                fontsize=args.font_size - 1,
                color="#555555")

    # ── Annotation panel ──────────────────────────────────────────────
    if has_annotations:
        ax_ann = fig.add_subplot(gs[1])
        draw_annotations(ax_ann, annotation_beds, args.font_size)
        ax_ann.set_xlim(ax.get_xlim())

    # ── Save ──────────────────────────────────────────────────────────
    plt.tight_layout()
    fig.savefig(args.output, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved {args.output}")


if __name__ == "__main__":
    main()