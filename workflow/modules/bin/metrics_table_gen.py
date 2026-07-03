import glob
import sys
import os
from Bio import SeqIO
from pathlib import Path
import gzip
import pysam
import pandas as pd
import csv
import glob
from Bio.SeqUtils import gc_fraction
import subprocess
import re
import pysam
# Example: python script.py /my/folder

# Directories
output_dir = sys.argv[1] if len(sys.argv) > 1 else "."
refs_dir = sys.argv[2] if len(sys.argv) > 2 else "."
fastp_dir = output_dir + "/fastp"
bm_dir = output_dir + "/bwamem2"
dedup_dir = output_dir + "/markduplicates"


def run_samtools_count(input_bam):
    stats = pysam.samtools.flagstat(input_bam, split_lines=True)
    return stats[0], stats[6], stats[4]


with open(refs_dir, mode='r', newline='', encoding='utf-8') as f:
    reader = csv.reader(f)
    
    # Optional: Skip the header row if your CSV has one
    next(reader) 
    
    # Extract the first column (index 0) from each row
    first_column = [row[0] for row in reader]

references = [item.replace(" ","_").lower() for item in first_column]

fastp_files = glob.glob(fastp_dir + "/*.trimmed.fastq.gz")

fastp_files = [item.split('/')[-1] for item in fastp_files]

sample_names = [item.replace(".trimmed.fastq.gz","") for item in fastp_files]
    
columns = ["sample", "reference", "total", "mapped_reads", "unmapped_reads", "duplicate_reads"]
# Create the DataFrame
df = pd.DataFrame(columns=columns)

for sample in sample_names:
    print(sample)
    for ref in references:
        print(ref)
        aligned_file = glob.glob(dedup_dir + f"/{sample}_{ref}.sorted.marked.bam")
        mapped = 0
        unmapped = 0
        duplicate = 0
        total, mapped, duplicate = run_samtools_count(aligned_file[0])
        
        total = total.split(" ")[0]
        mapped = mapped.split(" ")[0]
        duplicate = duplicate.split(" ")[0]
        unmapped = int(total) - int(mapped)
        # Close the files
        print(f"Mapped: {mapped}")
        print(f"Duplicates: {duplicate}")
        df.loc[len(df)] = [sample, ref, total, mapped, unmapped, duplicate]

# 1. Define your file path
filepath = Path(f"{output_dir}/metrics/metrics_table.csv")

# 2. Create parent directories if they do not exist
filepath.parent.mkdir(parents=True, exist_ok=True)

# 3. Save the DataFrame
df.to_csv(filepath, index=False)

print(df)