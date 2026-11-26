# workflow/rules/common.smk
import glob
import os
import re

def discover_samples_from_dir(wildcards=None):
    """
    Recursively search the configured input directory for FASTQ files
    and extract sample names from them.

    Expected filename pattern:
        14936_S12_L001_R1_001.fastq.gz
        14936_S12_L001_R2_001.fastq.gz

    The sample name is the prefix before the first underscore (e.g., "14936").

    The input directory is read from config["input_fastq_dir"].
    This function is evaluated at DAG-building time.
    """
    input_dir = config["input_fastq_dir"]

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
