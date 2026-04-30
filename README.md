# trapSeq
![Version](https://img.shields.io/badge/version-4.5.0-blue)

Targeted Retreival of Arthropod Borne Pathogen Sequences

## Highlights
- Customizable
- Returns consensus sequence
- Organized and easy to read visual reports
- CSV reports

---

## Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Parameters](#parameters)
- [Output](#output)
- [Citation](#citation)

---

## Requirements
- [Nextflow](https://www.nextflow.io/) `>=23.04`
- [Apptainer](https://apptainer.org/) `Formerly Singularity`

---

## Installation
> [!IMPORTANT]
> This pipeline is not ready for download yet.
```bash
git clone https://github.com/henry-j-sommer/TRAP-Seq.git
cd trap-seq
```

---


## Input

Reads should follow one of two naming conventions.

Convention 1: If lanes are already merged:
```
{sample_id}_R1.fastq.gz
{sample_id}_R2.fastq.gz
```

Convention 2: If lanes need to be merged:
```
{sample_id}_L1_R1.fastq.gz
{sample_id}_L2_R1.fastq.gz
{sample_id}_L1_R2.fastq.gz
{sample_id}_L2_R2.fastq.gz
```
If lanes need to be merged, the `--merge-lanes` parameter must be enabled.

All reads should be in the directory that you pass as `--indir`.

---

## Usage
```bash
nextflow run main.nf \
  --indir output_dir \
  --outdir results \
```

### Required arguments

| Parameter | Description |
|-----------|-------------|
| `--indir` | Path to FASTQ files |
| `--outdir` | Output directory |
| `--refs` | Either a list of paths, or a path to your `refs.csv` reference input file (see formatting below)|

### Optional arguments

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--min_depth` | `5` | Minimum depth for a position to not be masked |
| `--merge_lanes` | false | Merge lanes before proceeding with the pipeline |

### Reference Input File Formatting

In this case, the program receieves one reference, with a premade index. In reports, the reference will be referred to as "Zika Virus".

```csv
ref_path,ref_name,index_prefix
/my_folder/references/zikv.fa,Zika Virus,/my_folder/references/zikv
```
In this case, there is no premade index available, so the program will automatically create one.

```csv
ref_path,ref_name,index_prefix
/my_folder/references/wnv.fa,West Nile Virus,none
```
