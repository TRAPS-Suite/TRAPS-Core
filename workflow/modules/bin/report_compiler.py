import pandas as pd
import os
import sys
import pysam
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns

#script_dir = os.path.dirname(os.path.abspath(__file__))
#prefix = "../../results/workflow_metrics/"
#file_path_tr = prefix+"HC6A_trimmed_reads.tsv"
#file_path_rr = prefix+"HC6A_raw_reads.tsv"
#file_path_rm = prefix+"HC6A_reference_metrics.tsv"

#file_path1_tr = os.path.join(script_dir, file_path_tr)
#file_path1_rr = os.path.join(script_dir, file_path_rr)
#file_path1_dr = os.path.join(script_dir, file_path_dr)
#file_path1_rm = os.path.join(script_dir, file_path_rm)

file_path1_rr = sys.argv[1]
file_path1_tr = sys.argv[2]
file_path1_rm = sys.argv[3]
sample_id_in = sys.argv[4]



#### Compiling CSV report
custom_header = ["sample", "trimmed_reads"]
trimmed_reads = pd.read_csv(file_path1_tr, header=None, names=custom_header, sep='\t')
sample = trimmed_reads.iat[0,0]
custom_header = ["sample", "raw_reads"]
raw_reads = pd.read_csv(file_path1_rr, header=None, names=custom_header, sep='\t')
custom_header = ["reference", "mapped_reads", "cov_bases", "coverage_percent", "mean_depth"]
reference_metrics = pd.read_csv(file_path1_rm, header=None, names=custom_header, sep='\t')

raw_reads_num = raw_reads.iat[0, 1]
trimmed_reads_num = trimmed_reads.iat[0,1]
references_num = len(raw_reads) + 1
report_part = pd.DataFrame(columns=['sample', 'reads_raw', 'reads_trimmed', "reads_mapped", "coverage", "mean_depth", "reference"])


print(reference_metrics.iat[0, 2])

for i in range(references_num):
    n_sample = sample
    n_reads_raw = raw_reads_num
    n_reads_trimmed = trimmed_reads_num
    n_reads_mapped = reference_metrics.iat[i, 1]
    n_coverage = reference_metrics.iat[i, 2]
    n_mean_depth = reference_metrics.iat[i, 3]
    n_reference = reference_metrics.iat[i,0]
    new_row = [n_sample, n_reads_raw, n_reads_trimmed, n_reads_mapped, n_coverage, n_mean_depth, n_reference]
    report_part.loc[len(report_part)] = new_row

print(report_part.head())
report_part.to_csv(sample_id_in + '_report_part.csv', index=False)




