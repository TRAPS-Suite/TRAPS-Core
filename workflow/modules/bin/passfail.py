import pysam
import clpl
import numpy as np
import argparse
import os

parser = argparse.ArgumentParser(description="Cross Lab BAM file pathogen presence arbiter")
def check_bam_file(file_path):
    if not os.path.exists(file_path):
        raise argparse.ArgumentTypeError(f"The file '{file_path}' does not exist.")
    if not file_path.endswith('.bam'):
        raise argparse.ArgumentTypeError(f"The file '{file_path}' is not a valid .bam file.")
    return file_path

parser.add_argument(
    "--bam", 
    type=str, 
    required=True, 
    help="Path to the input BAM file (must have .bam extension)"
)
parser.add_argument(
    "--min-depth", 
    type=int, 
    required=True, 
    help="Path to the input BAM file (must have .bam extension)"
)
parser.add_argument(
    "--min-percent", 
    type=int, 
    required=True, 
    help="Path to the input BAM file (must have .bam extension)"
)

args = parser.parse_args()
bam = pysam.AlignmentFile(args.bam, "rb")
print(args.bam)
idxstats_output = pysam.idxstats(args.bam)
print("Reference\tMapped_Reads")
for line in idxstats_output.splitlines():
    fields = line.split("\t")
    ref_name = fields[0]
    mapped_count = fields[2]
    if ref_name != "*":
        print(f"{ref_name}\t{mapped_count}")
        if clpl.pass_breadth(bam, args.min_depth, args.min_percent, ref_name):
            print("Passed. Splitting!")
            clpl.split_passed(args.bam, ref_name)
        else:
            print("No")
