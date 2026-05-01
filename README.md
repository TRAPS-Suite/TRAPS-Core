# TRAPS

**T**argeted **R**etrieval and **A**nalysis of **A**rthopod Borne **P**athogen **S**equences

---

TRAPS is a scalable, highly customizable, and user friendly Nextflow pipeline for hybrid capture sequencing data, enabling detection of infections and coinfections with built in downstream analysis and reporting.
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
