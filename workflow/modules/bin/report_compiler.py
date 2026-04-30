import pandas as pd
import os
import sys
import matplotlib.pyplot as plt
import numpy as np
import pysam
import csv

outdir = sys.argv[1]

if(outdir[-1] == "/"):
    outdir = outdir[0:-1] + "/workflow_metrics"
else:
    outdir = outdir + "/workflow_metrics"

#print(outdir)

raw_metrics_files = os.listdir(outdir + "/raw_metrics")
trimmed_metrics_files = os.listdir(outdir + "/trimmed_metrics")
aligned_metrics_files = os.listdir(outdir + "/aligned_metrics")
deduped_metrics_files = os.listdir(outdir + "/deduped_metrics")

samples = []
raw_reads = []
reads_after_trimming = []
aligned_reads = []
reads_after_deduping = []
percent_genome_covered = []
mean_genomic_depth = []
mean_callable_depth = []
references = []




ref_num = 0


with open(outdir+f'/aligned_metrics/{aligned_metrics_files[0]}', 'r', newline='', encoding='utf-8') as tsvfile:
        reader = csv.reader(tsvfile, delimiter='\t')
        for row in reader:
            ref_num += 1
print(ref_num)

for mfile in raw_metrics_files:
    split_file_name = mfile.split("_raw")
    #print(split_file_name[0])
    for i in range(ref_num):
        samples.append(split_file_name[0])

for sample in samples:
    references = 0
    with open(outdir+f'/raw_metrics/{sample}_raw_reads.tsv', 'r', newline='', encoding='utf-8') as tsvfile:
        reader = csv.reader(tsvfile, delimiter='\t')
        for row in reader:
            #print(row[1])
            raw_reads.append(row[1])
    with open(outdir+f'/aligned_metrics/{sample}_aligned_metrics.tsv', 'r', newline='', encoding='utf-8') as tsvfile:
        # Specify the delimiter as a tab
        reader = csv.reader(tsvfile, delimiter='\t')

        # Iterate over each row
        for row in reader:
            references += 1
            #print(row)
    print(samples)
    print(raw_reads)