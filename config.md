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
