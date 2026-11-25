# Snakelet: A Modular Genomic Analysis Pipeline

[![Snakemake](https://img.shields.io/badge/snakemake-≥8.0-brightgreen.svg?style=flat)](https://snakemake.readthedocs.io)
[![Conda](https://img.shields.io/conda/vn/bioconda/snakemake?style=flat)](https://anaconda.org/bioconda/snakemake)

## Overview

**Snakelet** is a modular, reproducible, and scalable Snakemake workflow for bacterial genome analysis. It is the successor to the original Bash-based pipeline (`run_pipeline.sh`) and processes Illumina paired-end sequencing data from **BaseSpace download** to fully annotated and characterized genomes.

The pipeline is built on the following core principles:

- **Reproducibility**: Every rule uses a version-pinned Conda environment, ensuring identical software stacks across any system.
- **Portability**: The same `Snakefile` runs on a laptop, a shared server, or an HPC cluster via Snakemake profiles.
- **Flexibility**: The pipeline supports **alternative tools** for key analysis steps (e.g., FastQC vs. fastp, ABRicate vs. MOB-suite), configurable via a single configuration file.
- **Resumability**: Snakemake natively tracks file states, allowing the workflow to **start and stop at any point** without reprocessing completed steps.
- **Scalability**: Resource-aware scheduling (threads, memory) allows efficient execution on systems of any size.
- **Modularity**: Each analysis step is a self-contained rule module, facilitating maintenance, testing, and extension.
- **Configurability**: All user-specific parameters (input paths, database locations, sample metadata, tool selection) are externalized in configuration files.
- **Detailed Logging**: Per-sample and per-rule logs, benchmarks, and an optional email notification system provide full traceability.

## Table of Contents

1.  [Repository Structure](#1-repository-structure)
2.  [Pipeline Architecture](#2-pipeline-architecture)
3.  [Configurable Tool Sets](#3-configurable-tool-sets)
4.  [Configuration](#4-configuration)
5.  [Execution Control](#5-execution-control-start-and-stop-anywhere)
6.  [Resource Management & Portability](#6-resource-management--portability)
7.  [Software Environments](#7-software-environments)
8.  [Usage](#8-usage)
9.  [Migration from the Bash Pipeline](#9-migration-from-the-bash-pipeline)
10. [Implementation Plan](#10-implementation-plan)

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
│   │   ├── basespace.smk         # Step 1: Data download
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
│   │   ├── mob_suite.smk         # Alternative to ABRicate
│   │   ├── eggnog.smk
│   │   └── fastani.smk
│   ├── envs                      # Conda environment definitions per tool
│   │   ├── basespace.yaml
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

The workflow begins with the **BaseSpace download** and proceeds through quality control, assembly, annotation, and characterization. Dependencies are managed automatically by Snakemake.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     STEP 1: BASESPACE DOWNLOAD                             │
│                         (rule: basespace_download)                         │
│                                                                             │
│   Input: Run ID / Project ID (from config)                                  │
│   Output: results/01_basespace/{sample}/*.fastq.gz                         │
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
│   │  MOB-suite  │ (Alternative)                                             │
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

### Step 1: BaseSpace Download (`basespace.smk`)

The pipeline **starts** with data download from BaseSpace using the `bs` CLI. This is the first rule in the workflow, and all subsequent steps depend on its output.

```python
# workflow/rules/basespace.smk
# Download data from BaseSpace using the 'bs' CLI.

rule basespace_download:
    output:
        # The output is a directory containing the FASTQ files for a sample.
        directory("results/01_basespace/{sample}")
    params:
        # The BaseSpace project ID comes from the configuration.
        project_id=config["basespace"]["project_id"],
        dest="results/01_basespace/{sample}"
    conda:
        "../envs/basespace.yaml"
    log:
        "logs/basespace/{sample}.log"
    shell:
        """
        bs download project \
            -i {params.project_id} \
            -o {params.dest} \
            --extension fastq.gz \
            > {log} 2>&1
        """
```

> **Note**: The `bs download project` command downloads **all** FASTQs from a project. If you need to download files for a specific sample only, you can use `bs contents project` to list and filter file IDs before downloading. For simplicity, the rule above assumes one project per sample or a post-download organization step.

The sample sheet (`config/samples.tsv`) can include a column for the BaseSpace sample ID to map the downloaded files to the correct sample name.

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

When `qc.tool` is set to `"fastp"`, Snakemake will not request the FastQC outputs, and therefore the `rule fastqc` will not be executed. The `rule fastp` will be executed instead.

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

# --- BaseSpace Download -----------------------------------------------------
basespace:
  project_id: "your_basespace_project_id"  # BaseSpace project/run ID
  # Optional: API server URL (default: https://api.basespace.illumina.com/)
  # api_server: "https://api.basespace.illumina.com/"

# --- Tool Selection ---------------------------------------------------------
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

The sample sheet is a tab-separated file with columns `sample`, `fastq_r1`, and `fastq_r2`. Paths can be absolute, relative, or symlinks. For BaseSpace download, you can include a `basespace_sample_id` column to map downloaded files to sample names.

```tsv
sample	basespace_sample_id	fastq_r1	fastq_r2
sample_A	SAMPLE001	results/01_basespace/sample_A/sample_A_R1.fastq.gz	results/01_basespace/sample_A/sample_A_R2.fastq.gz
sample_B	SAMPLE002	results/01_basespace/sample_B/sample_B_R1.fastq.gz	results/01_basespace/sample_B/sample_B_R2.fastq.gz
```

> **Note**: The `fastq_r1` and `fastq_r2` paths are the expected locations **after** the BaseSpace download. The download rule populates `results/01_basespace/{sample}/`, and subsequent rules use these paths.

---

## 5. Execution Control (Start and Stop Anywhere)

One of the most powerful features of Snakemake is its ability to **resume from any point** without reprocessing completed steps. This replaces the manual `--start`, `--skip`, `--only`, and `--force` flags from the original Bash pipeline.

### How It Works

Snakemake tracks the state of each output file. When you run the workflow, it:

1.  Checks which output files already exist and are up-to-date.
2.  Determines which rules need to be executed to produce the missing or outdated files.
3.  Executes only those rules, in dependency order.

This means you can **interrupt the workflow at any time** and simply run the same command again to resume.

### Common Execution Control Commands

| Goal | Command | Description |
|------|---------|-------------|
| **Run everything** | `snakemake --profile workflow/profiles/default` | Executes all rules needed for the final targets. |
| **Stop at a specific step** | `snakemake --profile workflow/profiles/default --until spades` | Runs all rules up to and including `spades`, then stops. |
| **Start from a specific step** | `snakemake --profile workflow/profiles/default results/06_prokka/sample_A/sample_A.gff` | Runs only the rules needed to produce the specified file (and its dependencies). |
| **Skip a step** | `snakemake --profile workflow/profiles/default --omit-from spades` | Runs everything **except** `spades` and its dependencies. |
| **Force re-execution of a rule** | `snakemake --profile workflow/profiles/default --forcerun spades` | Re-executes `spades` and all downstream rules, even if outputs exist. |
| **Resume after failure** | `snakemake --profile workflow/profiles/default` | Simply run the same command again. Snakemake will continue from where it failed. |
| **Dry-run** | `snakemake --profile workflow/profiles/default -n -p` | Shows what would be executed without actually running anything. |

### Examples

#### Stop After Assembly

```bash
# Run BaseSpace download, QC, and SPAdes assembly, then stop.
snakemake --profile workflow/profiles/default --until spades
```

#### Start from Prokka (Assuming SPAdes Output Exists)

```bash
# Run only the rules needed to produce Prokka output for sample_A.
snakemake --profile workflow/profiles/default results/06_prokka/sample_A/sample_A.gff
```

#### Skip Assembly and Run Downstream Steps

```bash
# Run everything except SPAdes and its dependencies.
# This is useful if you already have assemblies from another source.
snakemake --profile workflow/profiles/default --omit-from spades
```

#### Force Re-execution of Kraken2

```bash
# Re-run Kraken2 and all downstream rules (e.g., Bracken).
snakemake --profile workflow/profiles/default --forcerun kraken2
```

### Handling `temp()` Files

If a rule's output is marked as `temp()`, Snakemake will delete it after all downstream rules have consumed it. This saves disk space but means that if you later need to re-run a downstream rule, the temporary file must be regenerated. To avoid this, either:

-   Do not use `temp()` for files that are expensive to regenerate.
-   Use `--notemp` to disable deletion of temporary files.

```bash
# Keep all temporary files (useful for debugging or partial re-runs)
snakemake --profile workflow/profiles/default --notemp
```

---

## 6. Resource Management & Portability

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

## 7. Software Environments

Every rule is annotated with an isolated, version-pinned Conda environment, defined in `workflow/envs/`. This guarantees reproducibility and avoids software conflicts.

Example: `workflow/envs/basespace.yaml`

```yaml
channels:
  - bioconda
  - conda-forge
  - defaults
dependencies:
  - basespace-cli=0.13.0
```

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

## 8. Usage

### Prerequisites

-   Snakemake (≥ 8.0)
-   Conda (Miniconda or Anaconda)
-   Git
-   BaseSpace CLI credentials (for the download step)

### Basic Commands

```bash
# 1. Clone the repository
git clone https://github.com/ICC-BioGC/Snakelet.git
cd Snakelet

# 2. Edit the configuration to set your BaseSpace project ID and tool preferences
nano config/config.yaml

# 3. Edit the sample sheet to list your samples
nano config/samples.tsv

# 4. Perform a dry-run to check the workflow logic
snakemake --profile workflow/profiles/default -n -p

# 5. Run the complete workflow locally using Conda
snakemake --profile workflow/profiles/default

# 6. Run on an HPC cluster (SLURM)
snakemake --profile workflow/profiles/slurm

# 7. Lint the workflow to check for best-practice violations
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

## 9. Migration from the Bash Pipeline

This project is a direct evolution of the original `run_pipeline.sh`. The table below maps concepts from the old pipeline to their Snakemake equivalents.

| Bash Pipeline Concept | Snakemake Equivalent |
|-----------------------|----------------------|
| `run_pipeline.sh` orchestration | `workflow/Snakefile` |
| CLI arguments (`-r`, `-o`, etc.) | `config/config.yaml` + `--config` flags |
| `run_*.sh` per-tool scripts | `workflow/rules/*.smk` |
| BaseSpace download (first step) | `rule basespace_download` in `basespace.smk` |
| Checkpoints (`mark_completed`, `is_completed`) | Native DAG-based re-execution; `--rerun-incomplete` |
| Resource monitoring (`monitor_process`) | `benchmark:` directive + Snakemake scheduler |
| `check_step_success` | Native output file validation |
| `ensure_*_env` functions | `conda:` directive per rule |
| `--start STEP` | `snakemake <target_file>` or `--until <rule>` |
| `--skip STEPS` | `--omit-from <rule>` |
| `--only STEPS` | Specify target files directly (e.g., `snakemake results/08_rgi/...`) |
| `--force` | `--forceall` or `--forcerun <rule>` |
| Email notifications (`send_email_with_log`) | Success/error handlers (`onsuccess`, `onerror`) |
| Tool selection (hardcoded) | `config/config.yaml` with `qc.tool`, `plasmid.tool`, etc. |

---

## 10. Implementation Plan

This project will be built incrementally, starting with the core structure and then adding each tool module.

-   [x] **Phase 0: Core Structure**
    -   [x] Define repository layout
    -   [x] Create `README.md`
    -   [x] Set up `config/config.yaml` and `config/samples.tsv`
    -   [x] Create `workflow/Snakefile` and `workflow/rules/common.smk`
    -   [x] Define execution profiles

-   [ ] **Phase 1: Implement Core Rule Modules** (one per tool, starting with BaseSpace)
    -   [ ] `basespace.smk` (BaseSpace download) — **First step**
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
