# TRAP-Seq
**T**argeted **R**etrieval of **A**rthropod-borne **P**athogen **Seq**uences

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
```bash
git clone https://github.com/henry-j-sommer/TRAP-Seq.git
cd trap-seq
```

---


## Input

Reads must follow the naming convention:
```
{sample_id}_R1.fastq.gz
{sample_id}_R2.fastq.gz
```
All reads should be in the directory that you pass as `--indir`.

---

## Usage
```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  -profile docker
```

### Required arguments

| Parameter | Description |
|-----------|-------------|
| `--indir` | Path to FASTQ files |
| `--outdir` | Output directory |

### Optional arguments

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--max_cpus` | `16` | Max CPUs per process |
| `--max_memory` | `128.GB` | Max memory per process |
| `--min_depth` | `5` | Minimum depth for a position to not be masked |
