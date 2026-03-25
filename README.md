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

## Usage
```bash
nextflow run your-org/pipeline-name \
  --input samplesheet.csv \
  --outdir results \
  -profile docker
```

### Required arguments

| Parameter | Description |
|-----------|-------------|
| `--input` | Path to samplesheet (CSV) |
| `--outdir` | Output directory |

### Optional arguments

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--genome` | `GRCh38` | Reference genome |
| `--max_cpus` | `16` | Max CPUs per process |
| `--max_memory` | `128.GB` | Max memory per process |

### Profiles

| Profile | Description |
|---------|-------------|
| `docker` | Run with Docker |
| `singularity` | Run with Singularity |
| `conda` | Run with Conda |
| `test` | Run with test data |
```
