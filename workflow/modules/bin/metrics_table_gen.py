import glob
import sys
import os
from Bio import SeqIO
from pathlib import Path
import gzip
import pysam
import pandas as pd
import csv
# Example: python script.py /my/folder
search_dir = sys.argv[1] if len(sys.argv) > 1 else "."
reports_dir = sys.argv[2] if len(sys.argv) > 2 else "."
pattern = os.path.join(search_dir, "*20x_cov_deduped.txt") 

output_dir = "/work/crosslab/hsommer/run4"
fastp_dir = Path(output_dir + "/fastp")
bm_dir = Path(output_dir + "/bwamem2")

with open('/work/crosslab/hsommer.csv', mode='r', newline='', encoding='utf-8') as f:
    reader = csv.reader(f)
    
    # Optional: Skip the header row if your CSV has one
    next(reader) 
    
    # Extract the first column (index 0) from each row
    first_column = [row[0] for row in reader]



fastpfiles = [str(file) for file in fastp_dir.glob("*.fastq.gz") if file.is_file() and not file.name.endswith("trimmed.fastq.gz")]
print(fastpfiles)

sample_names = []
for file in fastpfiles:
    filesplit = file.split("_S")
    filesplit = filesplit[0].split("/")
    sample_name = filesplit[len(filesplit)-1]
    sample_names.append(sample_name)

bm2files = [str(file) for file in bm_dir.glob("*.bam") if file.is_file()]

columns = ["sample", "reference", "fastq_reads", "mapped_reads", "unmapped_reads"]
# Create the DataFrame
df = pd.DataFrame(columns=columns)
print(df)


def count_fastq_reads(filename):
    # Open the gzipped file in text mode ('rt')
    with gzip.open(filename, 'rt') as f:
        # Loop through lines using a generator expression to minimize overhead
        line_count = sum(1 for line in f)
    
    # Each FASTQ read is exactly 4 lines
    return line_count // 4


def count_aligned_reads(bam_path):
    reads = 0
    # Open the BAM file
    with pysam.AlignmentFile(bam_path, "rb") as bam_file:
        # Iterate over all reads in the file
        for read in bam_file.fetch():
            # Filter for mapped reads
            if not read.is_unmapped:
                # Example: Print the read name and its mapped sequence
                reads += 1
    
    return(reads)


for file in fastpfiles:
    print("fastq reads: " + str(count_fastq_reads(file)))

   

for file in bm2files:
    for name in sample_names:
        for refname in ref_names:
            if(name+"-" or name+"_" in bam_path):
                print("Sample: " + name)
    print("mapped reads: " + str(count_aligned_reads(file)))

#read_count = count_fasta_reads(output_dir + "/bwamem2/.fasta")
#print(f"Total reads: {read_count}")
