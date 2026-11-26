# =============================================================================
# workflow/rules/common.smk
# Shared helper functions for the Snakelet workflow.
# =============================================================================

import glob
import os
import re

# =============================================================================
# STEP DIRECTORY HELPERS
# =============================================================================

def get_step_dir(step_name):
    """
    Return the full path for a given step directory, as defined in
    config["step_dirs"].

    Args:
        step_name: Key in config["step_dirs"] (e.g., "fastp", "fastqc").

    Returns:
        Full path (e.g., "results/02_qc/02_01_fastp").
    """
    if step_name not in config["step_dirs"]:
        raise ValueError(
            f"Step '{step_name}' not found in config['step_dirs']. "
            f"Available steps: {list(config['step_dirs'].keys())}"
        )
    return f"{config['outdir']}/{config['step_dirs'][step_name]}"


# =============================================================================
# SAMPLE DISCOVERY
# =============================================================================

# Cache to avoid re-scanning the directory for every call to get_fastq.
_FASTQ_CACHE = None


def discover_samples_from_dir(wildcards=None):
    """
    Recursively search the configured input directory for FASTQ files
    and extract sample names from them.

    Expected filename pattern (Illumina):
        14936_S12_L001_R1_001.fastq.gz
        14936_S12_L001_R2_001.fastq.gz

    The sample name is the prefix before the first underscore (e.g., "14936").

    The input directory is read from config["input_fastq_dir"].
    This function is evaluated at DAG-building time.

    Returns:
        Sorted list of unique sample names.
    """
    input_dir = config["input_fastq_dir"]

    if not os.path.isdir(input_dir):
        raise ValueError(
            f"Input directory '{input_dir}' does not exist or is not a directory."
        )

    # Recursive pattern for paired-end FASTQ files
    pattern = os.path.join(input_dir, "**", "*_R{1,2}_001.fastq.gz")
    fastq_files = glob.glob(pattern, recursive=True)

    samples = set()
    for fq in fastq_files:
        basename = os.path.basename(fq)
        # Extract everything before the first underscore
        sample_name = basename.split("_")[0]
        if sample_name:
            samples.add(sample_name)

    if not samples:
        raise ValueError(
            f"No FASTQ files found in '{input_dir}' matching pattern "
            f"'*_R{{1,2}}_001.fastq.gz'. Please check the directory and filenames."
        )

    return sorted(samples)


def _build_fastq_cache():
    """
    Scan the input directory once and build a dictionary mapping
    sample name -> {"r1": path, "r2": path}.

    This is called lazily by get_fastq() on first use.
    """
    global _FASTQ_CACHE
    if _FASTQ_CACHE is not None:
        return

    input_dir = config["input_fastq_dir"]
    pattern = os.path.join(input_dir, "**", "*_R{1,2}_001.fastq.gz")
    fastq_files = glob.glob(pattern, recursive=True)

    cache = {}
    for fq in fastq_files:
        basename = os.path.basename(fq)
        sample_name = basename.split("_")[0]
        if not sample_name:
            continue

        if sample_name not in cache:
            cache[sample_name] = {}

        if "_R1_001.fastq.gz" in basename:
            cache[sample_name]["r1"] = fq
        elif "_R2_001.fastq.gz" in basename:
            cache[sample_name]["r2"] = fq

    # Validate that every sample has both R1 and R2
    for sample, files in cache.items():
        if "r1" not in files or "r2" not in files:
            raise ValueError(
                f"Sample '{sample}' is missing R1 or R2 file. "
                f"Found: {files}"
            )

    _FASTQ_CACHE = cache


def get_fastq(wildcards):
    """
    Return the list of FASTQ files (R1, R2) for a given sample.

    Uses a cached mapping built by _build_fastq_cache() on first call.

    Args:
        wildcards: Snakemake wildcards object with a .sample attribute.

    Returns:
        List of two file paths [R1, R2].
    """
    _build_fastq_cache()
    sample = wildcards.sample

    if sample not in _FASTQ_CACHE:
        raise ValueError(
            f"Sample '{sample}' not found in input directory "
            f"'{config['input_fastq_dir']}'."
        )

    return [_FASTQ_CACHE[sample]["r1"], _FASTQ_CACHE[sample]["r2"]]
