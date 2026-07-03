# TRAPS

<img width="877" height="367" alt="traps_logo_v6" src="https://github.com/user-attachments/assets/46a2b9bd-36c5-4b85-a259-87a0b6a081d4" />


**T**argeted **R**etrieval and **A**nalysis of **A**rthopod Borne **P**athogen **S**equences

---

TRAPS is a scalable, highly customizable, and user friendly Nextflow pipeline for hybrid capture sequencing data, enabling detection of infections and coinfections with built in downstream analysis and visual reporting.

## Project Overview
### Features
- **Highly Customizable** Configure TRAPS for your use case
- **Built In Analyzation** Downstream consensus generation, coverage statistics
- **Scalable** Input as many samples and references as needed
- **Sensitive** TRAPS analyzes every sample for every reference, ensuring that both infections and coinfections are detected
- **Phylogenetic Mapping**

### Upcoming Features
- **Annotation** TRAPS transfers annotations from some references to the final output
- **Run Management** Runs are saved in a custom system using the `.tar` format
- **Mutation Reporting** Confidence scoring of amino acid mutations, with an option to add mutations to "flag"
- **Reports** An interactive web app enables graphical analysis of the data collected

## Usage
### Quick Start
Requirements:
- Apptainer
- Nextflow

Clone the GitHub Repo:
```bash
git clone -b dev https://github.com/henry-j-sommer/TRAPS.git
```
Navigate to the workflow directory in your new `TRAPS` folder.

```bash
cd TRAPS/workflow
```

Run the script to build containers
```bash
../containers/build-scripts/build-all
```

It is recommended to store your runs in a dedicated folder. Create a new folder, and remember the name.

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
Run TRAPS with `nextflow run main.nf -params-file {params file}` within the workflow directory.

### Storage

## Formatting
### FASTQ Filenames
This pipeline expects either single or paired end FASTQ files named using the following format:
```text
{SAMPLEID}_S{NUMBER}_L00{LANE}_R{READ}_001.fastq.gz
```


### References
The references file should be in `CSV` format.
`CSV` should follow this syntax:
| ref_name_external | ref_path |
|----------|----------|
| (reference name) | (reference location) |

For both formats, the `ref_name_external` refers to the human readable name of the reference that you want to use to refer to the reference. The `ref_path` refers to the absolute path to your reference in the FASTA format.

References can be in the `.fasta` or `.gb` format.



