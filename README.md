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



## Quick Start
## Usage
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
> If your `--outdir` flag points to a directory that already contains a TRAPS run, the program will **not** store the run there. Instead, it will save it in a directory in the same directory as the target.


