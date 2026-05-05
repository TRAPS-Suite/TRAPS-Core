# TRAPS Config

## First Steps
Your config file should a `.yaml`.

Paste this starter code in:
```yaml
indir:
trimming:
  tool:
alignment:
  tool:
filename:
  sampleid:
  copy:
  technology:
  date:
  lab:
  operator:
```

Next, fill out the configuration file for your preferences. 
Example:
```yaml
indir: "/home/myworkdir"
outdir: "/home/my_pipeline_run"
trimming:
  tool: "fastp"
alignment:
  tool: "bwamem2"
```

### Sample ID Configuration
TRAPS gives you the ability to edit the way it parses your filenames. To start, look at this example filename.
`HC0_100_ILL_203_LAB`
An underscore is used as the divider. This will be parsed into:

| Position  | Value |
| --| ----  |
| 1 | `HCO` |
| 2 | `100` |
| 3 | `ILL` |
| 4 | `203` |
| 5 | `LAB` |

In this example, the user wants their sample ID to be the prefix of the filename, followed by the copy number. They also want to include the technology metadata. They would use this syntax to achieve this.

```yaml
filename:
  sampleid: 1, 2
  copy: 1
  technology: 3
  date:
  lab:
  operator:
```

| Metadata | Value |
| -------- | ----- |
| `sampleid` | "HC0_100" |
| `copy` | "100" |
| `technology` | "ILL" |
| `date` | none |
| `lab` | none |
| `operator` | none |

As shown, the user correctly enters which slot their target value is in. To concatenate slots, add them together with a comma. 
