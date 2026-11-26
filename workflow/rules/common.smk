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

# workflow/rules/common.smk (continuação)

def get_fastq(wildcards):
    """
    Return the list of FASTQ files (R1, R2) for a given sample.

    Searches the configured input directory recursively for files
    matching the sample name and the expected Illumina naming pattern.
    """
    input_dir = config["input_fastq_dir"]
    sample = wildcards.sample

    # Pattern to find R1 and R2 for this sample, anywhere under input_dir
    pattern = os.path.join(input_dir, "**", f"{sample}_*_R{{1,2}}_001.fastq.gz")
    matches = glob.glob(pattern, recursive=True)

    # Separate R1 and R2
    r1 = [f for f in matches if "_R1_001.fastq.gz" in f]
    r2 = [f for f in matches if "_R2_001.fastq.gz" in f]

    if len(r1) != 1 or len(r2) != 1:
        raise ValueError(
            f"Expected exactly one R1 and one R2 file for sample '{sample}', "
            f"but found R1={r1}, R2={r2}."
        )

    return [r1[0], r2[0]]
