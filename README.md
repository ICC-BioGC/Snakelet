# Snakelet: A Modular Genomic Analysis Pipeline

[![Snakemake](https://img.shields.io/badge/snakemake-≥8.0-brightgreen.svg?style=flat)](https://snakemake.readthedocs.io)
[![Conda](https://img.shields.io/conda/vn/bioconda/snakemake?style=flat)](https://anaconda.org/bioconda/snakemake)

## Overview

**Snakelet** is a modular, reproducible, and scalable Snakemake workflow for bacterial genome analysis. It is the successor to the original Bash-based pipeline (`run_pipeline.sh`) and is designed to process Illumina paired-end sequencing data from raw reads to fully annotated and characterized genomes.

The pipeline is built on the following core principles:

- **Reproducibility**: Every rule uses a version-pinned Conda environment, ensuring identical software stacks across any system.
- **Portability**: The same `Snakefile` runs on a laptop, a shared server, or an HPC cluster via Snakemake profiles.
- **Flexibility**: The pipeline supports **alternative tools** for key analysis steps (e.g., FastQC vs. fastp, ABRicate vs. MOB-suite), configurable via a single configuration file.
- **Scalability**: Resource-aware scheduling (threads, memory) allows efficient execution on systems of any size.
- **Modularity**: Each analysis step is a self-contained rule module, facilitating maintenance, testing, and extension.
- **Configurability**: All user-specific parameters (input paths, database locations, sample metadata, tool selection) are externalized in configuration files.
- **Detailed Logging**: Per-sample and per-rule logs, benchmarks, and an optional email notification system provide full traceability.

## Table of Contents

1.  [Repository Structure](#1-repository-structure)
2.  [Pipeline Architecture](#2-pipeline-architecture)
3.  [Configurable Tool Sets](#3-configurable-tool-sets)
4.  [Configuration](#4-configuration)
5.  [Resource Management & Portability](#5-resource-management--portability)
6.  [Software Environments](#6-software-environments)
7.  [Usage](#7-usage)
8.  [Migration from the Bash Pipeline](#8-migration-from-the-bash-pipeline)
9.  [Implementation Plan](#9-implementation-plan)

---

## 1. Repository Structure

The repository follows the [recommended Snakemake layout](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html#distribution-and-reproducibility).

```
.
├── .gitignore
├── README.md
├── LICENSE.md
├── workflow
│   ├── Snakefile                 # Main entry point
│   ├── rules
│   │   ├── common.smk            # Shared helper functions
│   │   ├── basespace.smk
│   │   ├── fastqc.smk
│   │   ├── fastp.smk             # Alternative to FastQC
│   │   ├── spades.smk
│   │   ├── quast.smk
│   │   ├── busco.smk             # Alternative/complement to QUAST
│   │   ├── checkm.smk
│   │   ├── prokka.smk
│   │   ├── mlst.smk
│   │   ├── rgi.smk
│   │   ├── kraken2.smk
│   │   ├── bracken.smk
│   │   ├── abricate.smk
│   │   ├── mob_suite.smk         # Alternative to ABRicate (plasmid analysis)
│   │   ├── eggnog.smk
│   │   └── fastani.smk
│   ├── envs                      # Conda environment definitions per tool
│   │   ├── fastqc.yaml
│   │   ├── fastp.yaml
│   │   ├── spades.yaml
│   │   ├── quast.yaml
│   │   ├── busco.yaml
│   │   └── ...
│   ├── scripts                   # Custom Python/R helper scripts
│   │   ├── send_email.py
│   │   └── ...
│   └── profiles                  # Execution profiles (local, slurm, etc.)
│       ├── default
│       │   └── config.yaml
│       └── slurm
│           └── config.yaml
├── config
│   ├── config.yaml               # Main workflow configuration
│   └── samples.tsv               # Sample sheet
├── resources                     # Reference genomes, databases, etc.
└── results                       # All workflow output is written here
```

---

## 2. Pipeline Architecture

The workflow processes samples through the following steps, with dependencies managed automatically by Snakemake. The `rule all` in the `Snakefile` dynamically determines which tools to execute based on the configuration.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SAMPLE INPUT (FASTQ)                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         QUALITY CONTROL (Configurable)                     │
│   ┌─────────────┐                                                           │
│   │   FastQC    │ (Default)                                                 │
│   └─────────────┘                                                           │
│   ┌─────────────┐                                                           │
│   │   fastp     │ (Alternative)                                             │
│   └─────────────┘                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ASSEMBLY (SPAdes)                                │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ASSEMBLY QC (Configurable)                           │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                      │
│   │    QUAST    │   │    BUSCO    │   │   CheckM    │                      │
│   └─────────────┘   └─────────────┘   └─────────────┘                      │
│   (Default)         (Optional)        (Default)                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     ANNOTATION & CHARACTERIZATION                          │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                      │
│   │   Prokka    │   │    MLST     │   │     RGI     │                      │
│   └─────────────┘   └─────────────┘   └─────────────┘                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   PLASMID/VIRULENCE ANALYSIS (Configurable)                │
│   ┌─────────────┐                                                           │
│   │  ABRicate   │ (Default)                                                 │
│   └─────────────┘                                                           │
│   ┌─────────────┐                                                           │
│   │  MOB-suite   │ (Alternative)                                            │
│   └─────────────┘                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    TAXONOMY & FUNCTIONAL ANALYSIS                          │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                      │
│   │  Kraken2    │──▶│   Bracken   │   │   eggNOG    │                      │
│   └─────────────┘   └─────────────┘   └─────────────┘                      │
│   ┌─────────────┐                                                           │
│   │   fastANI   │                                                           │
│   └─────────────┘                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Configurable Tool Sets

A key feature of **Snakelet** is the ability to select alternative tools for specific analysis steps. This is controlled by the `config/config.yaml` file. The default scenario runs the complete, established pipeline, but users can switch tools as needed.

### Available Tool Alternatives

| Analysis Step | Default Tool | Alternative(s) | Configuration Key |
|---------------|--------------|----------------|-------------------|
| **Quality Control** | FastQC + MultiQC | fastp | `qc.tool` |
| **Assembly QC** | QUAST | BUSCO (can be enabled alongside QUAST) | `assembly_qc.quast`, `assembly_qc.busco` |
| **Plasmid/Virulence** | ABRicate | MOB-suite | `plasmid.tool` |
| **Completeness** | CheckM | (BUSCO can serve as an alternative) | `assembly_qc.checkm` |

### How It Works

1.  **Configuration-Driven**: The user sets their preferred tools in `config/config.yaml`.
2.  **Dynamic Target Selection**: The `rule all` in the `Snakefile` reads the configuration and only requests the output files for the selected tools.
3.  **All Rules Included**: All rule modules are included in the `Snakefile`, but Snakemake only executes the rules needed to produce the requested final targets.

### Example: Choosing fastp over FastQC

In `config/config.yaml`:

```yaml
qc:
  tool: "fastp"  # Options: "fastqc" (default) or "fastp"
```

The `Snakefile` logic:

```python
# workflow/Snakefile

# ... (config loading)

# Build final targets dynamically
final_targets = []

if config["qc"]["tool"] == "fastqc":
    final_targets.extend(expand(f"{OUTDIR}/02_fastqc/{{sample}}_fastqc.html", sample=SAMPLES))
    final_targets.append(f"{OUTDIR}/02_fastqc/multiqc_report.html")
elif config["qc"]["tool"] == "fastp":
    final_targets.extend(expand(f"{OUTDIR}/02_fastp/{{sample}}.html", sample=SAMPLES))

# ... (other targets)

rule all:
    input:
        final_targets
```

When `qc.tool` is set to `"fastp"`, Snakemake will not request the FastQC outputs, and therefore the `rule fastqc` will not be executed. The `rule fastp` will be executed instead, producing the required HTML reports.

### Example: Enabling BUSCO Alongside QUAST

In `config/config.yaml`:

```yaml
assembly_qc:
  quast: true
  busco: true   # Set to true to run BUSCO
  checkm: true
```

The `Snakefile` will add both QUAST and BUSCO outputs to the final targets, and Snakemake will execute both rules independently.

### Example: Choosing MOB-suite over ABRicate

In `config/config.yaml`:

```yaml
plasmid:
  tool: "mob_suite"  # Options: "abricate" (default) or "mob_suite"
```

The `Snakefile` will request MOB-suite outputs instead of ABRicate outputs.

---

## 4. Configuration

Configuration is split into two files.

### `config/config.yaml`

This file holds all tool-specific parameters, database paths, and **tool selection**.

```yaml
# Main configuration for the Snakelet workflow.

# --- Sample sheet -----------------------------------------------------------
samples: "config/samples.tsv"

# --- Tool Selection (NEW) ---------------------------------------------------
qc:
  tool: "fastqc"  # Options: "fastqc" (default), "fastp"

assembly_qc:
  quast: true
  busco: false    # Set to true to enable BUSCO
  checkm: true

plasmid:
  tool: "abricate"  # Options: "abricate" (default), "mob_suite"

# --- Database directories ---------------------------------------------------
kraken2_db: "/path/to/kraken2/database"
checkm_db: "/path/to/checkm/database"
rgi_db: "/path/to/rgi/database"
abricate_db: "/path/to/abricate/database"
eggnog_db: "/path/to/eggnog/database"
fastani_ref_dir: "resources/references"
busco_lineage: "bacteria_odb10"  # BUSCO lineage dataset

# --- Tool-specific parameters -----------------------------------------------
mlst_scheme: "abaumannii_2"
eggnog_tax_scope: "Bacteria"
bracken_read_length: 150

# --- Output directory -------------------------------------------------------
outdir: "results"
```

### `config/samples.tsv`

The sample sheet is a tab-separated file with columns `sample`, `fastq_r1`, and `fastq_r2`. Paths can be absolute, relative, or symlinks.

```tsv
sample	fastq_r1	fastq_r2
sample_A	/path/to/sample_A_R1.fastq.gz	/path/to/sample_A_R2.fastq.gz
sample_B	/path/to/sample_B_R1.fastq.gz	/path/to/sample_B_R2.fastq.gz
```

---

## 5. Resource Management & Portability

To adapt from a local workstation to a shared server or HPC cluster, **Snakelet** uses two complementary strategies:

1.  **Dynamic Resource Detection**: The workflow includes a Python function (in `common.smk`) that inspects system resources at startup and sets conservative defaults for shared environments.
2.  **Execution Profiles**: Pre-configured profiles in `workflow/profiles/` allow users to switch between execution environments with a single flag.

### `workflow/profiles/default/config.yaml` (Local Workstation)

```yaml
cores: 8
software-deployment-method: conda
printshellcmds: true
verbose: true
rerun-incomplete: true
keep-going: true
```

### `workflow/profiles/slurm/config.yaml` (HPC Cluster)

```yaml
executor: slurm
jobs: 50
software-deployment-method: conda
default-resources:
  - mem_mb=8000
  - runtime=60
printshellcmds: true
rerun-incomplete: true
keep-going: true
```

To run with a profile: `snakemake --profile workflow/profiles/default`

---

## 6. Software Environments

Every rule is annotated with an isolated, version-pinned Conda environment, defined in `workflow/envs/`. This guarantees reproducibility and avoids software conflicts.

Example: `workflow/envs/spades.yaml`

```yaml
channels:
  - bioconda
  - conda-forge
  - defaults
dependencies:
  - spades=3.15.5
```

Example: `workflow/envs/fastp.yaml`

```yaml
channels:
  - bioconda
  - conda-forge
  - defaults
dependencies:
  - fastp=0.23.4
```

Example: `workflow/envs/busco.yaml`

```yaml
channels:
  - bioconda
  - conda-forge
  - defaults
dependencies:
  - busco=5.6.1
```

The full list of environments is available in the `workflow/envs/` directory.

---

## 7. Usage

### Prerequisites

-   Snakemake (≥ 8.0)
-   Conda (Miniconda or Anaconda)
-   Git

### Basic Commands

```bash
# 1. Clone the repository
git clone https://github.com/ICC-BioGC/Snakelet.git
cd Snakelet

# 2. Edit the configuration to select your preferred tools
nano config/config.yaml

# 3. Perform a dry-run to check the workflow logic
snakemake --profile workflow/profiles/default -n -p

# 4. Run the complete workflow locally using Conda
snakemake --profile workflow/profiles/default

# 5. Run on an HPC cluster (SLURM)
snakemake --profile workflow/profiles/slurm

# 6. Lint the workflow to check for best-practice violations
snakemake --lint
```

### Selecting Alternative Tools

To use `fastp` instead of `FastQC`, edit `config/config.yaml`:

```yaml
qc:
  tool: "fastp"
```

Then run the pipeline as usual. Snakemake will automatically execute `fastp` and skip `FastQC`.

To enable `BUSCO` alongside `QUAST`, edit `config/config.yaml`:

```yaml
assembly_qc:
  quast: true
  busco: true
```

### Email Notifications

The original Bash pipeline included email notifications. In Snakemake, this is handled via **success/error handlers**. A custom script (`workflow/scripts/send_email.py`) will be added and referenced in the `Snakefile` to replicate this functionality.

```python
# In Snakefile
onsuccess:
    print("Workflow completed successfully!")
    # shell("python workflow/scripts/send_email.py --status SUCCESS ...")

onerror:
    print("Workflow failed!")
    # shell("python workflow/scripts/send_email.py --status FAILURE ...")
```

---

## 8. Migration from the Bash Pipeline

This project is a direct evolution of the original `run_pipeline.sh`. The table below maps concepts from the old pipeline to their Snakemake equivalents.

| Bash Pipeline Concept | Snakemake Equivalent |
|-----------------------|----------------------|
| `run_pipeline.sh` orchestration | `workflow/Snakefile` |
| CLI arguments (`-r`, `-o`, etc.) | `config/config.yaml` + `--config` flags |
| `run_*.sh` per-tool scripts | `workflow/rules/*.smk` |
| Checkpoints (`mark_completed`, `is_completed`) | Native DAG-based re-execution; `--rerun-incomplete` |
| Resource monitoring (`monitor_process`) | `benchmark:` directive + Snakemake scheduler |
| `check_step_success` | Native output file validation |
| `ensure_*_env` functions | `conda:` directive per rule |
| `--only`, `--skip`, `--start` flags | `snakemake <target>` + `--until`, `--omit-from` |
| Email notifications (`send_email_with_log`) | Success/error handlers (`onsuccess`, `onerror`) |
| `--force` | `--forceall`, `--forcerun` |
| Tool selection (hardcoded) | `config/config.yaml` with `qc.tool`, `plasmid.tool`, etc. |

---

## 9. Implementation Plan

This project will be built incrementally, starting with the core structure and then adding each tool module.

-   [x] **Phase 0: Core Structure**
    -   [x] Define repository layout
    -   [x] Create `README.md`
    -   [x] Set up `config/config.yaml` and `config/samples.tsv`
    -   [x] Create `workflow/Snakefile` and `workflow/rules/common.smk`
    -   [x] Define execution profiles

-   [ ] **Phase 1: Implement Core Rule Modules** (one per tool)
    -   [ ] `fastqc.smk` (FastQC + MultiQC)
    -   [ ] `spades.smk` (SPAdes assembly)
    -   [ ] `quast.smk` (QUAST)
    -   [ ] `checkm.smk` (CheckM)
    -   [ ] `prokka.smk` (Prokka)
    -   [ ] `mlst.smk` (MLST)
    -   [ ] `rgi.smk` (RGI)
    -   [ ] `kraken2.smk` (Kraken2)
    -   [ ] `bracken.smk` (Bracken)
    -   [ ] `abricate.smk` (ABRicate)
    -   [ ] `eggnog.smk` (eggNOG-mapper)
    -   [ ] `fastani.smk` (fastANI)
    -   [ ] `basespace.smk` (BaseSpace download)

-   [ ] **Phase 2: Implement Alternative Tool Modules**
    -   [ ] `fastp.smk` (alternative to FastQC)
    -   [ ] `busco.smk` (complement/alternative to QUAST)
    -   [ ] `mob_suite.smk` (alternative to ABRicate)

-   [ ] **Phase 3: Auxiliary Features**
    -   [ ] Implement email notification handlers
    -   [ ] Add report generation (Snakemake `report` directive)
    -   [ ] Set up continuous integration (GitHub Actions)
    -   [ ] Add test data and integration tests

-   [ ] **Phase 4: Validation & Documentation**
    -   [ ] Run `snakemake --lint` and address all issues
    -   [ ] Format all `.smk` files with `snakefmt`
    -   [ ] Finalize documentation and usage examples
    -   [ ] Tag a stable release (e.g., `v1.0.0`)

---

## License

This project is licensed under the MIT License. See the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

-   This workflow structure is based on the [Snakemake Workflow Template](https://github.com/snakemake-workflows/snakemake-workflow-template).
-   We thank the developers of all the open-source bioinformatics tools integrated into this pipeline.
