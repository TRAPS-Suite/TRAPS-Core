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
- **Annotation** TRAPS transfers annotations from some references to the final output

## Usage
### Quick Start
Requirements:
- Apptainer
- Nextflow

Clone the GitHub Repo:
```bash
git clone https://github.com/henry-j-sommer/TRAPS.git
```
Navigate to the directory that contains the new `TRAPS` folder.

It is recommended to store your runs in a dedicated folder. If you already have a folder, you can ignore this.
Create a storage folder:
```bash
mkdir my_traps_runs
```

Enter the workflow directory:
```bash
cd TRAPS/workflow
```

Make sure your `.FASTQ` files are stored in a dedicated directory and follow the [formatting guidelines]([url](https://github.com/henry-j-sommer/TRAPS.git)).
Make sure your [reference configuration file]([url](https://github.com/henry-j-sommer/TRAPS.git)) is created.

### Configuration
Create your [configuration file](config.md) to edit naming format, tools used, and other parameters. 

> [!WARNING]
> Any parameter passed in the CLI will take priority over a configuration file.

| Flag | Name | Explanation | Type |
| -------- | -------- | -------| -------|
| `--indir` | Input Directory | Reads to run | path |
| `--outdir` | Output Directory | Output | path |
| `--refs` | Reference File | Which references to run against | path |
| `-params-file` | Configuration File | A path pointing to your [configuration file](config.md) | path |

### Running
Run TRAPS with `nextflow run main.nf` within the workflow directory.
> [!TIP]
> If your `--outdir` flag points to a directory, and your `--runname` flag is identical to a run within this directory, TRAPS will not run. It is recommended to change your `--runname` for separate runs.

### Storage
TRAPS is stored in single archives with the `.traps` extension.

## Formatting
### FASTQ Filenames
The `fastq` read files you want to run in the pipeline should follow this syntax:
### References
The references file should be in `CSV`, `TSV`, or `JSON` format.
`CSV` and `TSV` should follow this syntax:
| ref_name | ref_path |
|----------|----------|
| (reference name) | (reference location) |

`JSON` should follow this syntax:
```json
[
  {
    "ref_name": "(reference name)",
    "ref_path": "(refereance path)"
  }
]
```
For both formats, the `ref_name` refers to the human readable name of the reference that you want to use to refer to the reference. The `ref_path` refers to the path to your reference.

References can be in the `.fasta` or `.gb` format.



