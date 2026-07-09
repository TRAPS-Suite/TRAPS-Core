import pysam
import clpl
import numpy as np


def filter_read(read):
        return not read.is_duplicate

def pass_breadth(bam, min_depth, min_percent, reference):
    cov = np.sum(
        bam.count_coverage(
            contig=reference,
            quality_threshold=0,
            read_callback=filter_read
        ),
        axis=0
    )

    percent = np.count_nonzero(cov >= min_depth) / len(cov) * 100

    if percent >= min_percent:
        return(True)
    else:
        return(False)
    print(f"{percent:.2f}%")

def split_passed(bam, reference):
    pysam.samtools.view("-b", "-o", f"{reference}_passed.bam", bam, reference)
