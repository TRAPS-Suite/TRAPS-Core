import pysam
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import sys
from matplotlib.backends.backend_pdf import PdfPages

sns.set_theme(style="ticks", context="talk")
sns.despine()
BIN_SIZE = 50
PANELS_PER_PAGE = 3
layers = 30
inf = sys.argv[1]
index_path = sys.argv[2]
pos = inf.split("/")
filename = pos[len(pos) - 1]
savelist = filename.split(".marked")
savename = savelist[0]

output_pdf = f"{savename}_coverage_report.pdf"



# Open the BAM/SAM/CRAM file (must be indexed for random access)
samfile = pysam.AlignmentFile(inf, "rb", index_filename=index_path)

contigs = samfile.references

# Iterate through all contigs/chromosomes in the header

#ax.fill_between(xs, ys, 1e-2, color=color, alpha=0.4)
color = sns.color_palette("mako")[3]

total = 0
totalpos = 0

with PdfPages(output_pdf) as pdf:

    for page_start in range(0, len(contigs), PANELS_PER_PAGE):

        subset = contigs[page_start:page_start + PANELS_PER_PAGE]

        fig, axes = plt.subplots(len(subset), 1, figsize=(7, 8), sharex=False)

        if len(subset) == 1:
            axes = [axes]

        fig.suptitle(f"Coverage Report — {savename}", fontsize=18)

        # ENUMERATION happens here
        for ax, contig in zip(axes, subset):

            contig_len = samfile.get_reference_length(contig)

            xs = []
            ys = []

            for start in range(0, contig_len, BIN_SIZE):
                end = min(start + BIN_SIZE, contig_len)
                  # create an array to hold per-base coverage for this bin
                bin_coverage = np.zeros(end - start, dtype=int)

                # fetch all reads overlapping this bin
                for read in samfile.fetch(contig, start, end):
                    if read.is_unmapped or read.is_duplicate:
                        continue  # skip duplicates and unmapped reads

                    # get aligned positions (ignores soft-clips)
                    for query_pos, ref_pos in read.get_aligned_pairs(matches_only=True):
                        if ref_pos is not None and start <= ref_pos < end:
                            bin_coverage[ref_pos - start] += 1

                # median coverage per bin
                depth = np.median(bin_coverage)

                xs.append(start)    
                ys.append(depth)

                total += depth
                totalpos += 1



            ys = np.array(ys)

            # fix zeros for log scale


            # gradient fill
            layers = 20
            for i in range(layers):

                lower = ys * (i / layers)
                upper = ys * ((i + 1) / layers)

                ax.fill_between(
                    xs,
                    lower,
                    upper,
                    color=color,
                    alpha=0.04,
                    linewidth=0
                )

            if ys.any():
                avg = total/totalpos
            else:
                avg = 0

            # coverage line
            ax.plot(xs, ys, color="black", linewidth=1)
            
            ax.axhline(y=avg, color='r', linestyle='--', label='Average Depth: ' + str(avg))


            try:
                ezcontig = easynameref[contig]
                title = f"{savename} - {contig} - {ezcontig}"
            except:
                title = f"{savename} - {contig}"

            ax.set_title(title, loc="left")

            ax.set_ylabel("Coverage")

            ax.margins(x=0)

        axes[-1].set_xlabel("Genomic Position")

        sns.despine()

        plt.tight_layout()

        # Add this figure as a new page
        pdf.savefig(fig)
        plt.close(fig)  # important to free memory
samfile.close()