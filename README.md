<img width="100%" alt="logoText(1)" src="https://github.com/user-attachments/assets/a407ae11-2800-401d-b455-e53ee913d889" />
A Nextflow pipeline for processing hybrid capture sequencing data to align and analyze pathogen sequences

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
- [Docker](https://www.docker.com/) / [Singularity](https://sylabs.io/) / [Conda](https://conda.io/)

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

### Optional arguments

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--min_depth` | `5` | Minimum depth for a position to not be masked |
| `--merge_lanes` | false | Merge lanes before proceeding with the pipeline |
