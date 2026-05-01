# TRAPS

**T**argeted **R**etrieval and **A**nalysis of **A**rthopod Borne **P**athogen **S**equences

---

TRAPS is a scalable, highly customizable, and user friendly Nextflow pipeline for hybrid capture sequencing data, enabling detection of infections and coinfections with built in downstream analysis and reporting.

## Project Overview
### Features
- **Highly Customizable** Configure TRAPS for your use case
- **Built In Analyzation** Downstream consensus generation, coverage statistics, mutation details, and more
- **Scalable** Input as many samples and references as needed
- **Sensitive** TRAPS analyzes every sample for every reference, ensuring that both infections and coinfections are detected
- **Reports** An interactive web app enables graphical analysis of the data collected
- **Run Management** Runs are saved in a custom system using the `.tar` format

## Usage
### Quick Start
Requirements:
- Apptainer
- Nextflow

```bash
git clone traps
```
### Configuration
You can configure TRAPS through a [configuration file](config.md) passed in the CLI, or with [flags](config.md) passed in the CLI. For reproducibility, it is recommended to create a configuration file for highly customized settings. Basic parameters are shown below.

> [!IMPORTANT]
> Any parameter passed in the CLI will take priority over a configuration file.

| Flag | Name | Explanation | Type |
| -------- | -------- | -------| -------|
| `--indir` | Input Directory | Reads to run | path |
| `--outdir` | Output Directory | Output | path |
| `--singleend` | Single End | Are reads single end? | bool |
| `--refs` | Reference File | Which references to run against | path |

### Running
Run TRAPS with `nextflow run main.nf` within the workflow directory.
> [!IMPORTANT]
> If your `--outdir` flag points to a directory, and your `--runname` flag is identical to a run within this directory, TRAPS will not run. Change your `--runname`

### Storage
TRAPS is stored in single archives with the `.traps` extension.
